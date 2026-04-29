//
//  HomeView.swift
//  SecretMBTICounselor
//

import SwiftUI

struct HomeView: View {
    @Environment(\.notionTerms) private var notionTerms

    @AppStorage("hasShownDisclaimer") private var hasShownDisclaimer = false
    @AppStorage("hasShownUnsupportedAlert") private var hasShownUnsupportedAlert = false
    @State private var showDisclaimer = false
    @State private var showUnsupported = false
    @State private var unsupportedStatus: AIAvailability.Status = .unknown
    @State private var showSettings = false
    @State private var selectedMBTI: MBTIType?
    @State private var favorites = FavoritesStore.shared

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ZStack {
                    AppTheme.background.ignoresSafeArea()
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            header
                            bestiesSection
                            othersSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                }

//                HomeBannerAdContainer()
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
            .onAppear {
                if !hasShownDisclaimer {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        withAnimation(.spring(duration: 0.3)) {
                            showDisclaimer = true
                        }
                    }
                } else {
                    checkAIAvailabilityIfNeeded()
                }
            }
            .onChange(of: showDisclaimer) { _, newValue in
                if !newValue {
                    hasShownDisclaimer = true
                    checkAIAvailabilityIfNeeded()
                }
            }
            .onChange(of: showUnsupported) { _, newValue in
                if !newValue { hasShownUnsupportedAlert = true }
            }
            .overlay {
                if showDisclaimer {
                    DisclaimerView(isPresented: $showDisclaimer)
                        .zIndex(999)
                } else if showUnsupported {
                    UnsupportedDeviceView(status: unsupportedStatus, isPresented: $showUnsupported)
                        .zIndex(999)
                }
            }
        }
    }

    // MARK: - AI 가용성 체크

    private func checkAIAvailabilityIfNeeded() {
        guard !hasShownUnsupportedAlert else { return }
        let status = AIAvailability.status
        guard status != .available else { return }
        unsupportedStatus = status
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(duration: 0.3)) {
                showUnsupported = true
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("오늘은 누구에게\n마음을 털어놓을까요?")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .lineSpacing(4)
            Text(favorites.hasAnyBestie
                 ? "단짝 상담사와 먼저 이야기해보세요"
                 : "카드를 길게 눌러 위로 끌어올리면 단짝이 돼요")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }

    // MARK: - Sections

    private var bestiesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                icon: "heart.fill",
                iconColor: Color(hex: "FF8FA3"),
                title: "단짝 상담사",
                subtitle: favorites.besties.isEmpty ? "여기에 끌어다 놓으세요" : nil
            )

            if favorites.besties.isEmpty {
                emptyBestiesDropZone
            } else {
                grid(for: favorites.besties, inBesties: true)
            }
        }
    }

    private var othersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                icon: "person.2.fill",
                iconColor: AppTheme.textSecondary,
                title: "다른 상담사",
                subtitle: nil
            )

            grid(for: favorites.others, inBesties: false)
        }
    }

    private func sectionHeader(icon: String, iconColor: Color, title: String, subtitle: String?) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundStyle(iconColor)
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
        }
    }

    private var emptyBestiesDropZone: some View {
        HStack {
            Spacer()
            VStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18))
                    .foregroundStyle(AppTheme.textSecondary)
                Text("아직 비어있어요")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
        }
        .frame(height: 88)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerMedium)
                .strokeBorder(AppTheme.textSecondary.opacity(0.25), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
        )
        .dropDestination(for: String.self) { items, _ in
            guard let raw = items.first, let mbti = MBTIType(rawValue: raw) else { return false }
            withAnimation(.easeInOut(duration: 0.2)) {
                favorites.appendToBesties(mbti)
            }
            return true
        }
    }

    // MARK: - Grid

    private func grid(for types: [MBTIType], inBesties: Bool) -> some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(types) { type in
                Button { selectedMBTI = type } label: {
                    MBTICardView(type: type)
                        .overlay(alignment: .topTrailing) {
                            if inBesties {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color(hex: "FF8FA3"))
                                    .padding(6)
                            }
                        }
                }
                .buttonStyle(.plain)
                .contentShape(.dragPreview, RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous))
                .draggable(type.rawValue) {
                    MBTICardView(type: type)
                        .frame(width: 76, height: 76)
                        .contentShape(.dragPreview, RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous))
                }
                .dropDestination(for: String.self) { items, _ in
                    guard let raw = items.first,
                          let dropped = MBTIType(rawValue: raw),
                          dropped != type else { return false }
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if inBesties {
                            favorites.move(dropped, toBestiesBefore: type)
                        } else {
                            favorites.move(dropped, toOthersBefore: type)
                        }
                    }
                    return true
                }
            }
        }
        .dropDestination(for: String.self) { items, _ in
            // 카드 사이가 아닌 섹션 빈 공간에 드롭 시 섹션 끝으로
            guard let raw = items.first, let mbti = MBTIType(rawValue: raw) else { return false }
            withAnimation(.easeInOut(duration: 0.2)) {
                if inBesties {
                    favorites.appendToBesties(mbti)
                } else {
                    favorites.appendToOthers(mbti)
                }
            }
            return true
        }
    }
}
