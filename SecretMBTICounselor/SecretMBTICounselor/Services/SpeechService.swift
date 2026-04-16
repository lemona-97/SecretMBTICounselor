//
//  SpeechService.swift
//  SecretMBTICounselor
//
//  STT: SFSpeechRecognizer + AVAudioEngine
//  TTS: AVSpeechSynthesizer (MBTI 보이스 프로파일 + 문장 단위 큐 재생)
//

import Foundation
import AVFoundation
import Speech

@MainActor
@Observable
final class SpeechService: NSObject {

    var isRecording = false
    var isSpeaking = false
    var transcript: String = ""
    var lastError: String?

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ko-KR"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    // MARK: - Permissions

    func requestPermissions() async -> Bool {
        let speech = await withCheckedContinuation { (c: CheckedContinuation<Bool, Never>) in
            SFSpeechRecognizer.requestAuthorization { c.resume(returning: $0 == .authorized) }
        }
        let mic = await withCheckedContinuation { (c: CheckedContinuation<Bool, Never>) in
            AVAudioApplication.requestRecordPermission { c.resume(returning: $0) }
        }
        return speech && mic
    }

    // MARK: - STT

    func startRecording() async {
        guard !isRecording else { return }
        guard await requestPermissions() else {
            lastError = "마이크/음성 인식 권한이 필요해요"
            return
        }
        guard let recognizer, recognizer.isAvailable else {
            lastError = "현재 음성 인식을 사용할 수 없어요"
            return
        }

        do {
            let audio = AVAudioSession.sharedInstance()
            try audio.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
            try audio.setActive(true, options: .notifyOthersOnDeactivation)

            let req = SFSpeechAudioBufferRecognitionRequest()
            req.shouldReportPartialResults = true
            self.request = req

            let input = audioEngine.inputNode
            let format = input.outputFormat(forBus: 0)
            input.removeTap(onBus: 0)
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                self?.request?.append(buffer)
            }
            audioEngine.prepare()
            try audioEngine.start()

            transcript = ""
            isRecording = true

            recognitionTask = recognizer.recognitionTask(with: req) { [weak self] result, error in
                guard let self else { return }
                Task { @MainActor in
                    if let result { self.transcript = result.bestTranscription.formattedString }
                    if error != nil || (result?.isFinal ?? false) { self.stopRecording() }
                }
            }
        } catch {
            lastError = error.localizedDescription
            stopRecording()
        }
    }

    func stopRecording() {
        guard isRecording || audioEngine.isRunning else { return }
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        recognitionTask?.finish()
        request = nil
        recognitionTask = nil
        isRecording = false
    }

    // MARK: - TTS

    func speak(_ text: String, mbti: MBTIType? = nil) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        stopSpeaking()

        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? AVAudioSession.sharedInstance().setActive(true, options: [])

        let voice = mbti?.preferredVoice() ?? AVSpeechSynthesisVoice(language: "ko-KR")
        let profile = mbti?.voiceProfile

        for (idx, chunk) in Self.splitIntoChunks(trimmed).enumerated() {
            let u = AVSpeechUtterance(string: chunk)
            u.voice = voice
            u.rate = profile?.rate ?? (AVSpeechUtteranceDefaultSpeechRate * 0.98)
            u.pitchMultiplier = profile?.pitch ?? 1.0
            u.preUtteranceDelay = (idx == 0 ? 0 : (profile?.preDelay ?? 0.04))
            u.postUtteranceDelay = profile?.postDelay ?? 0.05
            synthesizer.speak(u)
        }
    }

    func stopSpeaking() {
        if synthesizer.isSpeaking || synthesizer.isPaused {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }

    // MARK: - Sentence splitter

    static func splitIntoChunks(_ text: String, maxLen: Int = 80) -> [String] {
        var sentences: [String] = []
        var buf = ""
        let enders: Set<Character> = [".", "!", "?", "…", "。", "!", "?", "\n"]
        for ch in text {
            buf.append(ch)
            if enders.contains(ch) {
                let t = buf.trimmingCharacters(in: .whitespacesAndNewlines)
                if !t.isEmpty { sentences.append(t) }
                buf = ""
            }
        }
        let tail = buf.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tail.isEmpty { sentences.append(tail) }

        var result: [String] = []
        for s in sentences {
            if s.count <= maxLen { result.append(s) }
            else { result.append(contentsOf: splitLong(s, maxLen: maxLen)) }
        }
        return result.isEmpty ? [text] : result
    }

    private static func splitLong(_ s: String, maxLen: Int) -> [String] {
        let parts = s.split(whereSeparator: { ",，、".contains($0) }).map {
            $0.trimmingCharacters(in: .whitespaces)
        }
        var out: [String] = []
        for p in parts where !p.isEmpty {
            if p.count <= maxLen { out.append(p); continue }
            var cur = ""
            for w in p.split(separator: " ") {
                if cur.count + w.count + 1 > maxLen, !cur.isEmpty {
                    out.append(cur); cur = String(w)
                } else {
                    cur = cur.isEmpty ? String(w) : cur + " " + w
                }
            }
            if !cur.isEmpty { out.append(cur) }
        }
        return out
    }
}

extension SpeechService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ s: AVSpeechSynthesizer, didStart u: AVSpeechUtterance) {
        Task { @MainActor in self.isSpeaking = true }
    }
    nonisolated func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish u: AVSpeechUtterance) {
        Task { @MainActor in if !s.isSpeaking { self.isSpeaking = false } }
    }
    nonisolated func speechSynthesizer(_ s: AVSpeechSynthesizer, didCancel u: AVSpeechUtterance) {
        Task { @MainActor in self.isSpeaking = false }
    }
}
