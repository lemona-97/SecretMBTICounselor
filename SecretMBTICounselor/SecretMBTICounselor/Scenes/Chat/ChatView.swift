//
//  ChatView.swift
//  SecretMBTICounselor
//

import SwiftUI
import SwiftData

struct ChatView: View {
    let session: ChatSession

    @Environment(\.modelContext) private var modelContext
    @AppStorage("defaultInteractionMode") private var defaultModeRaw: String = InteractionMode.chat.rawValue
    @AppStorage("autoPlayTTS") private var autoPlayTTS: Bool = true

    @Query private var knownTerms: [UserTerm]
    @State private var viewModel: ChatViewModel?

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            if let vm = viewModel {
                VStack(spacing: 0) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(vm.sortedMessages) { msg in
                                    MessageBubbleView(message: msg, mbti: vm.mbti)
                                        .id(msg.id)
                                }
                                if vm.isResponding, vm.sortedMessages.last?.role != .assistant {
                                    TypingIndicatorView(mbti: vm.mbti)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .onChange(of: vm.sortedMessages.last?.id) { _, id in
                            guard let id else { return }
                            withAnimation { proxy.scrollTo(id, anchor: .bottom) }
                        }
                        .onChange(of: vm.sortedMessages.last?.content) { _, _ in
                            if let id = vm.sortedMessages.last?.id {
                                proxy.scrollTo(id, anchor: .bottom)
                            }
                        }
                    }

                    Divider().overlay(AppTheme.divider)

                    Group {
                        if vm.mode == .chat {
                            ChatInputBarView(
                                text: Binding(get: { vm.draft }, set: { vm.draft = $0 }),
                                accent: vm.mbti.accent,
                                isResponding: vm.isResponding
                            ) {
                                vm.sendDraft(autoPlayTTS: autoPlayTTS)
                            }
                        } else {
                            VoiceInputBarView(
                                isRecording: vm.speech.isRecording,
                                isSpeaking: vm.speech.isSpeaking,
                                transcript: vm.speech.transcript,
                                accent: vm.mbti.accent,
                                onMicTap: { vm.toggleMic(autoPlayTTS: autoPlayTTS) },
                                onStopSpeaking: { vm.stopSpeaking() }
                            )
                        }
                    }
                }
            }
        }
        .navigationTitle(session.mbti.nickname)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let vm = viewModel {
                    ModeToggleView(
                        mode: Binding(get: { vm.mode }, set: { vm.mode = $0 }),
                        accent: vm.mbti.accent
                    )
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                let mode = InteractionMode(rawValue: defaultModeRaw) ?? .chat
                viewModel = ChatViewModel(session: session, modelContext: modelContext, knownTerms: knownTerms, defaultMode: mode)
                Task { await viewModel?.speech.requestPermissions() }
            }
        }
        .onDisappear { viewModel?.cleanup() }
    }
}
