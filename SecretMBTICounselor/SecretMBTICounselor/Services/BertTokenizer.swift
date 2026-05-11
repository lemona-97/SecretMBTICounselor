//
//  BertTokenizer.swift
//  SecretMBTICounselor
//
//  klue/bert-base WordPiece 토크나이저 Swift 구현.
//  vocab.txt 를 앱 번들에서 로드합니다.
//

import Foundation

final class BertTokenizer {
    static let shared = BertTokenizer()

    private let vocab: [String: Int]
    private let unkId: Int
    private let clsId: Int
    private let sepId: Int
    private let padId: Int
    private let maxLen: Int = 128

    private init() {
        guard let url = Bundle.main.url(forResource: "vocab", withExtension: "txt"),
              let content = try? String(contentsOf: url, encoding: .utf8)
        else {
            fatalError("vocab.txt 를 앱 번들에 추가해주세요.")
        }
        var map: [String: Int] = [:]
        for (idx, line) in content.components(separatedBy: "\n").enumerated() {
            let token = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !token.isEmpty { map[token] = idx }
        }
        vocab  = map
        unkId  = map["[UNK]"] ?? 1
        clsId  = map["[CLS]"] ?? 2
        sepId  = map["[SEP]"] ?? 3
        padId  = map["[PAD]"] ?? 0
    }

    // 텍스트 → (input_ids: [Int32], attention_mask: [Int32]) 길이 128
    func encode(_ text: String) -> (inputIds: [Int32], attentionMask: [Int32]) {
        let tokens = tokenize(text)
        // [CLS] + tokens + [SEP], maxLen-2 로 자름
        let truncated = Array(tokens.prefix(maxLen - 2))
        var ids: [Int32] = [Int32(clsId)]
        ids += truncated.map { Int32(vocab[$0] ?? unkId) }
        ids += [Int32(sepId)]

        let validLen = ids.count
        let padding  = Array(repeating: Int32(padId), count: maxLen - validLen)
        ids += padding

        var mask = Array(repeating: Int32(1), count: validLen)
        mask    += Array(repeating: Int32(0), count: maxLen - validLen)

        return (ids, mask)
    }

    // WordPiece 토크나이저 (한국어: 어절 단위 분리 후 문자 레벨 WordPiece)
    private func tokenize(_ text: String) -> [String] {
        var result: [String] = []
        // 공백으로 어절 분리 후 각각 WordPiece 적용
        for word in text.split(separator: " ").map(String.init) {
            result += wordPiece(word)
        }
        return result
    }

    private func wordPiece(_ word: String) -> [String] {
        // 전체 단어가 vocab에 있으면 그대로
        if vocab[word] != nil { return [word] }

        var subTokens: [String] = []
        var remaining = word

        while !remaining.isEmpty {
            var found = false
            var end = remaining.endIndex

            // 가장 긴 매칭 prefix 찾기
            while end > remaining.startIndex {
                let prefix = remaining.startIndex == word.startIndex
                    ? String(remaining[remaining.startIndex..<end])
                    : "##" + String(remaining[remaining.startIndex..<end])

                if vocab[prefix] != nil {
                    subTokens.append(prefix)
                    remaining = String(remaining[end...])
                    found = true
                    break
                }
                end = remaining.index(before: end)
            }

            if !found {
                // 매칭 실패 → 문자 하나씩 분해
                let ch = String(remaining.removeFirst())
                let tok = subTokens.isEmpty ? ch : "##" + ch
                subTokens.append(tok)
            }
        }

        return subTokens.isEmpty ? ["[UNK]"] : subTokens
    }
}
