# 🌙 SecretMBTICounselor

16가지 MBTI 성격에 맞춘 AI 상담사와 음성 기반 대화를 나누는 iOS 앱입니다.
Apple의 온디바이스 Foundation Models를 활용하여 MBTI별 고유한 상담 스타일과 음성을 제공합니다.

## 🎯 주요 기능

- **16개 MBTI 상담사**: 각 MBTI별 고유한 성격과 상담 스타일
- **음성/텍스트 이중 입력**: 편한 방식으로 자유롭게 선택
- **온디바이스 AI**: Foundation Models를 활용한 프라이빗하고 빠른 응답
- **MBTI별 음성 프로필**: 성별과 톤이 다른 한국어 TTS 음성
- **대화 관리**: 대화 이름 변경, 삭제 (스와이프 또는 메뉴)
- **설정 관리**: 기본 입력 모드, 자동 TTS 재생, 햅틱 피드백

## 📊 프로젝트 구조

```
SecretMBTICounselor/
├── App/
│   └── SecretMBTICounselorApp.swift          # 앱 진입점, SwiftData 설정
│
├── Theme/
│   └── AppTheme.swift                        # 색상, 폰트, 레이아웃 상수
│
├── Models/
│   ├── ChatModels.swift                      # ChatSession, ChatMessage (SwiftData)
│   ├── MBTIType.swift                        # 16 MBTI 정의, 그래디언트, 아이콘
│   ├── MBTIPersona.swift                     # MBTI별 시스템 프롬프트
│   └── MBTIVoiceProfile.swift                # MBTI별 음성 프로필 (성별, 톤)
│
├── Services/
│   ├── CounselorService.swift                # LanguageModelSession 래핑, AI 응답
│   └── SpeechService.swift                   # STT/TTS, 음성 녹음/재생
│
└── Scenes/
    ├── Home/
    │   ├── HomeView.swift                    # 4×4 MBTI 카드 그리드 진입점
    │   └── Components/
    │       └── MBTICardView.swift            # 개별 MBTI 카드 (탭 → ChatListView)
    │
    ├── Settings/
    │   └── SettingsView.swift                # 기본 입력 모드, TTS, 햅틱 설정
    │
    ├── ChatList/
    │   ├── ChatListView.swift                # 해당 MBTI의 대화 목록
    │   ├── ChatListViewModel.swift           # 대화 생성, 이름변경, 삭제 로직
    │   └── Components/
    │       ├── ProfileHeaderView.swift       # MBTI 프로필 헤더 (이모지+닉네임)
    │       └── SessionRowView.swift          # 개별 대화 리스트 항목
    │
    └── Chat/
        ├── ChatView.swift                    # 대화 화면 메인 뷰
        ├── ChatViewModel.swift               # 메시지 송수신, 음성 상태 관리
        └── Components/
            ├── MessageBubbleView.swift       # 사용자/상담사 메시지 버블
            ├── TypingIndicatorView.swift     # 상담사 입력 중 애니메이션
            ├── ModeToggleView.swift          # 음성/텍스트 입력 모드 토글
            ├── ChatInputBarView.swift        # 텍스트 입력 바
            └── VoiceInputBarView.swift       # 음성 입력 바 (마이크 버튼, 스톱 버튼)
```

## 🔧 기술 스택

- **UI Framework**: SwiftUI
- **데이터**: SwiftData (`@Model`, `@Query`, `ModelContext`)
- **AI**: Foundation Models (`LanguageModelSession`)
- **음성**: Speech Recognition (`SFSpeechRecognizer`) + Text-to-Speech (`AVSpeechSynthesizer`)
- **상태 관리**: @Observable (MVVM 패턴)
- **동시성**: Swift 6 Strict Concurrency (`@MainActor`, `nonisolated`)
- **네비게이션**: NavigationStack, navigationDestination

## 📱 화면 구성

### 1. **HomeView** (진입점)
- 4×4 MBTI 카드 그리드
- 우상단 설정 버튼 → SettingsView 시트 표시
- 카드 탭 → ChatListView(mbti:)로 네비게이션

### 2. **ChatListView** (MBTI별 대화 목록)
- 프로필 헤더 (MBTI 정보)
- "새 대화 시작하기" 버튼
- 지난 대화 목록
  - **좌클릭**: 해당 대화 열기
  - **길게 누르기**: 이름변경/삭제 메뉴
  - **우스와이프**: 삭제/이름변경 버튼 노출 (풀스와이프 시 삭제 alert 표시)

### 3. **ChatView** (실제 대화)
- 스크롤 가능한 메시지 목록
- 우상단: 음성/텍스트 모드 토글
- 하단: 입력 바 (ChatInputBarView 또는 VoiceInputBarView)

**텍스트 모드 (`ChatInputBarView`)**:
- 멀티라인 텍스트 필드
- 송신 버튼 (비활성화 시 opacity 0.4)

**음성 모드 (`VoiceInputBarView`)**:
- 큰 마이크 원형 버튼 (녹음 중 빨강)
- 스톱 버튼 (재생 중일 때)
- 실시간 음성 인식 텍스트 표시

### 4. **SettingsView**
- 기본 입력 모드 선택 (음성/텍스트)
- 자동 TTS 재생 on/off
- 햅틱 피드백 on/off

## 🎨 디자인

**색상 팔레트** (AppTheme.swift):
- 배경: `#FBF7F4` (아이보리)
- 사용자 버블: `#FFE7D6` (살구색)
- 상담사 버블: `#F2ECFF` (연보라)
- 텍스트 Primary: `#1A1A1A`
- 텍스트 Secondary: `#8E8E93`
- 구분선: `#E5E5EA`

**MBTI별 테마**: 
각 MBTI마다 고유한 그래디언트 + 강조색 (Accent Color) 사용

## 🔄 데이터 흐름

### 1. **대화 세션 생성**
```
HomeView (탭)
  ↓
ChatListView (새 대화 시작)
  ↓
ChatListViewModel.createSession()
  ↓
SwiftData에 저장, ChatSession 반환
  ↓
ChatView로 네비게이션
```

### 2. **메시지 송수신**
```
사용자 입력 (ChatInputBarView/VoiceInputBarView)
  ↓
ChatViewModel.sendDraft() / toggleMic()
  ↓
CounselorService.streamReply()
  ↓
Foundation Models 스트림 처리
  ↓
ChatMessage 생성 & SwiftData 저장
  ↓
UI 업데이트 (LazyVStack 자동 스크롤)
```

### 3. **음성 재생**
```
AI 응답 완료
  ↓
SpeechService.speak(text, mbti)
  ↓
MBTIVoiceProfile 조회 (적절한 TTS 음성 선택)
  ↓
문장 단위 분할 (500자 초과 시)
  ↓
AVSpeechUtterance 큐 기반 순차 재생
```

## 🛠️ MVVM 패턴

### ViewModel 구성

**ChatListViewModel**:
```swift
@Observable @MainActor
final class ChatListViewModel {
    var renameTarget: ChatSession?
    var renameText: String = ""
    var deleteTarget: ChatSession?
    
    func createSession() -> ChatSession
    func beginRename(_ session: ChatSession)
    func confirmRename()
    func beginDelete(_ session: ChatSession)
    func confirmDelete()
}
```

**ChatViewModel**:
```swift
@Observable @MainActor
final class ChatViewModel {
    var draft: String = ""
    var mode: InteractionMode = .chat
    var isResponding: Bool = false
    var sortedMessages: [ChatMessage]
    var mbti: MBTIType
    
    func sendDraft(autoPlayTTS: Bool)
    func toggleMic(autoPlayTTS: Bool)
    func stopSpeaking()
    func cleanup()
}
```

## 🔐 스토리지

**SwiftData (로컬 DB)**:
- `ChatSession`: MBTI, 제목, 업데이트 시간, 메시지 목록
- `ChatMessage`: 역할(사용자/상담사), 내용, 상위 Session

**AppStorage (UserDefaults)**:
- `defaultInteractionMode`: 기본 입력 모드 (chat/voice)
- `autoPlayTTS`: 자동 TTS 재생 여부
- `hapticsEnabled`: 햅틱 피드백 여부

## 📞 주요 Service

### CounselorService
```swift
@Observable @MainActor
final class CounselorService {
    func reply(to messages: [ChatMessage]) async throws -> String
    func streamReply(to messages: [ChatMessage]) async throws -> AsyncThrowingStream<String, Error>
}
```
- LanguageModelSession으로 Foundation Models 래핑
- MBTI별 시스템 프롬프트 + 대화 히스토리 포함
- 스트림 기반 실시간 응답

### SpeechService
```swift
@Observable @MainActor
final class SpeechService: NSObject {
    var isRecording: Bool
    var isSpeaking: Bool
    var transcript: String
    
    func requestPermissions() async -> Bool
    func startRecording() async
    func stopRecording()
    func speak(_ text: String, mbti: MBTIType)
    func stopSpeaking()
}
```
- STT: 부분 결과 실시간 표시 (SFSpeechRecognitionTaskDelegate)
- TTS: 500자 초과 시 문장 단위 분할, 큐 기반 순차 재생

## ⚙️ 설정 & 권한

**Info.plist 필수 항목**:
- `NSMicrophoneUsageDescription`: 음성 녹음 권한
- `NSSpeechRecognitionUsageDescription`: 음성 인식 권한

**Build Settings**:
- Dark Mode 비활성화: `.preferredColorScheme(.light)`

## 🎭 MBTI 특성

각 MBTI는 다음 속성을 보유합니다:
- **닉네임**: 친근한 이름 (예: "완벽주의자 INTJ")
- **태그라인**: 한 줄 설명
- **이모지**: 대표 이모지
- **시스템 프롬프트**: 고유한 상담 스타일 (MBTIPersona.swift)
- **음성 프로필**: 성별, 톤, 선호 TTS 음성 (MBTIVoiceProfile.swift)
- **그래디언트 & 강조색**: 시각적 구분

## 🚀 빌드 & 실행

```bash
# Xcode에서 열기
open SecretMBTICounselor.xcodeproj

# 또는 SwiftUI Preview에서 실시간 확인
Cmd + Opt + Enter
```

**최소 요구사항**:
- iOS 17.0+
- Xcode 16.0+
- Apple Silicon (Foundation Models 지원)

## 📝 라이선스

개인 프로젝트
