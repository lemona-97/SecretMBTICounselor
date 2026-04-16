//
//  HomeView.swift
//  SecretMBTICounselor
//

import SwiftUI

struct HomeView: View {
    @State private var showSettings = false
    @State private var selectedMBTI: MBTIType?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ZStack {
                    AppTheme.background.ignoresSafeArea()
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            header
                            grid
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                }

                // 하단 배너 광고 (스크롤과 무관하게 항상 고정)
                HomeBannerAdContainer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Secret MBTI")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .navigationDestination(item: $selectedMBTI) { mbti in
                ChatListView(mbti: mbti)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("오늘은 누구에게\n마음을 털어놓을까요?")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .lineSpacing(4)
            Text("16명의 상담사가 기다리고 있어요")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(MBTIType.allCases) { type in
                Button { selectedMBTI = type } label: {
                    MBTICardView(type: type)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
