//
//  VoiceInputBarView.swift
//  SecretMBTICounselor
//

import SwiftUI

struct VoiceInputBarView: View {
    let isRecording: Bool
    let isSpeaking: Bool
    let transcript: String
    let accent: Color
    let onMicTap: () -> Void
    let onStopSpeaking: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            if !transcript.isEmpty {
                Text(transcript)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
            }

            HStack(spacing: 14) {
                if isSpeaking {
                    Button(action: onStopSpeaking) {
                        HStack(spacing: 6) {
                            Image(systemName: "stop.fill")
                            Text("그만 듣기").font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(AppTheme.textPrimary)
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(Capsule().fill(AppTheme.surface))
                        .overlay(Capsule().stroke(AppTheme.divider, lineWidth: 1))
                    }
                }

                Spacer()

                Button(action: onMicTap) {
                    ZStack {
                        Circle()
                            .fill(isRecording ? Color.red : accent)
                            .frame(width: 72, height: 72)
                            .shadow(color: (isRecording ? Color.red : accent).opacity(0.4), radius: 12, x: 0, y: 6)
                        Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .padding(.top, 10)
        .background(AppTheme.background)
    }
}
