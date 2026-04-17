//
//  ChatListView.swift
//  SecretMBTICounselor
//

import SwiftUI
import SwiftData

struct ChatListView: View {
    let mbti: MBTIType
    let notionTerms: [NotionTerm]

    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [ChatSession]
    @State private var viewModel: ChatListViewModel?
    @State private var pushedSession: ChatSession?

    init(mbti: MBTIType, notionTerms: [NotionTerm] = []) {
        self.mbti = mbti
        self.notionTerms = notionTerms
        let raw = mbti.rawValue
        let predicate = #Predicate<ChatSession> { $0.mbtiRaw == raw }
        _sessions = Query(filter: predicate, sort: [SortDescriptor(\ChatSession.updatedAt, order: .reverse)])
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ProfileHeaderView(mbti: mbti)

                    Button {
                        guard let vm = viewModel else { return }
                        pushedSession = vm.createSession()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                            Text("새 대화 시작하기")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.cornerMedium, style: .continuous)
                                .fill(mbti.gradient)
                                .shadow(color: mbti.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                    }

                    if !sessions.isEmpty {
                        Text("지난 대화")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                            .padding(.top, 4)
                    }

                    // 네이티브 광고 (세션이 있을 때만 표시)
                    if !sessions.isEmpty {
                        NativeAdRowView()
                    }

                    LazyVStack(spacing: 10) {
                        ForEach(sessions) { session in
                            Button { pushedSession = session } label: {
                                SessionRowView(session: session)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button {
                                    viewModel?.beginRename(session)
                                } label: { Label("이름 변경", systemImage: "pencil") }
                                Button(role: .destructive) {
                                    viewModel?.beginDelete(session)
                                } label: { Label("삭제", systemImage: "trash") }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    viewModel?.beginDelete(session)
                                } label: { Label("삭제", systemImage: "trash") }
                                Button {
                                    viewModel?.beginRename(session)
                                } label: { Label("이름", systemImage: "pencil") }
                                    .tint(.blue)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
                .padding(.top, 8)
            }
        }
        .navigationTitle(mbti.nickname)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel == nil {
                viewModel = ChatListViewModel(mbti: mbti, modelContext: modelContext)
            }
        }
        .navigationDestination(item: $pushedSession) { session in
            ChatView(session: session, notionTerms: notionTerms)
        }
        .alert("대화 이름 변경", isPresented: Binding(
            get: { viewModel?.renameTarget != nil },
            set: { if !$0 { viewModel?.cancelRename() } }
        )) {
            TextField("이름", text: Binding(
                get: { viewModel?.renameText ?? "" },
                set: { viewModel?.renameText = $0 }
            ))
            Button("취소", role: .cancel) { viewModel?.cancelRename() }
            Button("저장") { viewModel?.confirmRename() }
        }
        .alert("정말 삭제하시겠습니까?", isPresented: Binding(
            get: { viewModel?.deleteTarget != nil },
            set: { if !$0 { viewModel?.cancelDelete() } }
        )) {
            Button("취소", role: .cancel) { viewModel?.cancelDelete() }
            Button("확인", role: .destructive) { viewModel?.confirmDelete() }
        } message: {
            Text("삭제 후 복구는 불가능합니다.")
        }
    }
}