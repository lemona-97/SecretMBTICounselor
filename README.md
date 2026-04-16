# 🌙 Secret MBTI Counselor

16가지 MBTI 성격에 맞춘 AI 상담사와 대화를 나누는 iOS 앱입니다.
Apple의 온디바이스 Foundation Models를 활용해 완전한 프라이버시를 보장하면서, MBTI별로 고유한 말투·상담 스타일·음성을 제공합니다.

---

## 🎯 주요 기능

| 기능 | 설명 |
|------|------|
| **16개 MBTI 상담사** | 각 MBTI마다 고유한 닉네임, 말투, 상담 접근법 보유 |
| **온디바이스 AI** | Apple Foundation Models — 외부 서버 전송 없음, 완전 프라이빗 |
| **텍스트 / 음성 이중 입력** | 채팅 또는 마이크 입력 자유 선택 |
| **MBTI별 TTS 음성** | 성별·톤이 다른 한국어 음성으로 상담사 개성 표현 |
| **대화 관리** | 세션별 이름 변경, 스와이프 삭제, 대화 이어하기 |
| **AI 주의사항 안내** | 최초 실행 시 단 한 번, AI 한계·위기상담 전화 안내 팝업 |
| **설정** | 기본 입력 모드, 자동 TTS 재생, 햅틱 피드백 |

---

## 🧠 16명의 상담사

| MBTI | 닉네임 | 한 줄 컨셉 | 이모지 |
|------|--------|-----------|--------|
| INTJ | 전략가 지안 | 깊이 있는 통찰로 길을 제시해요 | 🔭 |
| INTP | 사색가 도윤 | 논리적으로 함께 고민해요 | 🧩 |
| ENTJ | 지휘관 하린 | 결단력 있게 방향을 잡아요 | ♟️ |
| ENTP | 토론가 시우 | 새로운 관점을 제안해요 | 💡 |
| INFJ | 옹호자 해원 | 마음 깊이 공감해요 | 🌙 |
| INFP | 중재자 윤슬 | 따뜻하게 마음을 어루만져요 | 🌷 |
| ENFJ | 선도자 라온 | 성장을 응원해요 | 🌻 |
| ENFP | 활동가 반디 | 에너지로 힘을 북돋아요 | 🎈 |
| ISTJ | 현실주의자 정우 | 단단한 조언을 드려요 | 📚 |
| ISFJ | 수호자 다정 | 조용히 곁을 지켜요 | 🍀 |
| ESTJ | 경영자 태오 | 현실적인 해결책을 찾아요 | 🗂️ |
| ESFJ | 집정관 소리 | 포근하게 안아드려요 | 🍰 |
| ISTP | 장인 겨울 | 담백하게 정리해드려요 | 🛠️ |
| ISFP | 모험가 하나 | 감성을 함께 나눠요 | 🎨 |
| ESTP | 사업가 라이 | 행동으로 돌파해요 | 🔥 |
| ESFP | 연예인 봄이 | 즐겁게 이야기해요 | 🎉 |

---

## 📱 화면 구성

### 1. HomeView — 진입점
- 4×4 MBTI 카드 그리드
- 최초 실행 시 AI 주의사항 팝업 (DisclaimerView) 자동 표시
- 우상단 설정 버튼 → SettingsView 시트

### 2. ChatListView — MBTI별 대화 목록
- 해당 MBTI 상담사 프로필 헤더
- "새 대화 시작하기" 버튼
- 이전 대화 목록
  - 탭 → 대화 이어하기
  - 길게 누르기 → 이름변경 / 삭제 메뉴
  - 좌스와이프 → 삭제 / 이름변경 버튼 (풀스와이프 시 삭제 확인 alert)

### 3. ChatView — 실제 대화
- 스트리밍 응답 (글자 단위 실시간 출력)
- 타이핑 인디케이터 애니메이션
- 우상단 음성 ↔ 텍스트 모드 토글
- 텍스트 모드: 멀티라인 입력 + 전송 버튼
- 음성 모드: 마이크 버튼(녹음 중 빨강) + 실시간 인식 텍스트 표시

### 4. DisclaimerView — AI 주의사항 팝업
- 앱 설치 후 최초 1회만 표시 (AppStorage로 영구 저장)
- 포함 내용:
  - AI 서비스임을 명시 (한국 AI기본법 준수)
  - 전문 심리치료·의료 대체 불가 안내
  - 위기 상황 시 전문기관 연락 권고
  - 위기상담 전화번호 (109 / 1577-0199 / 1388) — 탭 시 전화 연결
  - 온디바이스 저장 안내 (개인정보보호)

### 5. SettingsView — 설정
- 기본 입력 모드 (채팅 / 보이스)
- 자동 TTS 재생 on/off
- 햅틱 피드백 on/off

---

## 🔧 기술 스택

| 분류 | 사용 기술 |
|------|----------|
| **UI** | SwiftUI |
| **AI** | Apple Foundation Models (`LanguageModelSession`) |
| **데이터** | SwiftData (`@Model`, `@Query`) |
| **음성 입력** | Speech Framework (`SFSpeechRecognizer`) |
| **음성 출력** | AVFoundation (`AVSpeechSynthesizer`) |
| **상태 관리** | `@Observable` — MVVM 패턴 |
| **동시성** | Swift 6 Strict Concurrency (`@MainActor`, `nonisolated`) |
| **영구 저장** | AppStorage (UserDefaults) |
| **광고** | Google Mobile Ads SDK (AdMob) |

---

## 🤖 AI 시스템 프롬프트 구조

Instructions는 **영어**로 작성되어 Foundation Models의 의도 파악 정확도를 높이고, 응답은 **한국어**로 강제합니다.

```
[Speech Style]       → MBTI별 말투·어미·리듬 (16가지)
[Counseling Approach]→ MBTI별 상담 접근법 및 우선순위 (16가지)
[Core Rules]         → 공통 원칙 (존중, 위기 대응, 간결성, 후속 질문)
[Formatting Rules]   → 줄바꿈·띄어쓰기 규칙, 마크다운 금지
```

**히스토리 주입**: 새 세션 시작 시 이전 대화 최근 12개를 컨텍스트로 삽입 (언급하지는 않음)

**중복 제거**: 연속된 유사 문장을 Jaccard 유사도 기반으로 필터링

---

## 🔄 데이터 흐름

### 메시지 송수신
```
사용자 입력 (텍스트 or 음성 STT)
  ↓
ChatViewModel.sendDraft() / toggleMic()
  ↓
CounselorService.streamReply()
  ↓
Foundation Models 스트리밍 응답
  ↓
ChatMessage SwiftData 저장 + UI 실시간 업데이트
  ↓
(자동 TTS ON 시) SpeechService.speak()
```

### 음성 재생 (TTS)
```
AI 응답 완료
  ↓
MBTIVoiceProfile 조회 → 해당 MBTI 음성 선택
  ↓
500자 초과 시 문장 단위 분할
  ↓
AVSpeechUtterance 큐 기반 순차 재생
```

---

## 📊 프로젝트 구조

```
SecretMBTICounselor/
├── App/
│   └── SecretMBTICounselorApp.swift       # 앱 진입점, SwiftData 컨테이너, AdMob 초기화
│
├── Theme/
│   └── AppTheme.swift                     # 색상, 코너 반경 등 전역 디자인 상수
│
├── Models/
│   ├── ChatModels.swift                   # ChatSession, ChatMessage (SwiftData @Model)
│   ├── MBTIType.swift                     # 16 MBTI 정의, 닉네임, 이모지, 그래디언트
│   ├── MBTIPersona.swift                  # MBTI별 시스템 Instructions (영어)
│   └── MBTIVoiceProfile.swift             # MBTI별 TTS 음성 프로필
│
├── Services/
│   ├── CounselorService.swift             # Foundation Models 래퍼, 스트리밍 응답
│   └── SpeechService.swift               # STT 녹음 + TTS 재생
│
└── Scenes/
    ├── Home/
    │   ├── HomeView.swift                 # 4×4 그리드, 최초 팝업 트리거
    │   └── Components/
    │       └── MBTICardView.swift         # 개별 MBTI 카드
    │
    ├── Disclaimer/
    │   └── DisclaimerView.swift           # AI 주의사항 팝업 (최초 1회)
    │
    ├── Settings/
    │   └── SettingsView.swift             # 앱 설정
    │
    ├── ChatList/
    │   ├── ChatListView.swift             # MBTI별 대화 세션 목록
    │   ├── ChatListViewModel.swift        # 세션 생성·이름변경·삭제 로직
    │   └── Components/
    │       ├── ProfileHeaderView.swift    # MBTI 프로필 헤더
    │       └── SessionRowView.swift       # 대화 목록 행
    │
    └── Chat/
        ├── ChatView.swift                 # 대화 메인 화면
        ├── ChatViewModel.swift            # 메시지 송수신, 음성 상태 관리
        └── Components/
            ├── MessageBubbleView.swift    # 메시지 버블 (사용자/상담사)
            ├── TypingIndicatorView.swift  # 응답 대기 애니메이션
            ├── ModeToggleView.swift       # 텍스트/음성 모드 토글
            ├── ChatInputBarView.swift     # 텍스트 입력 바
            └── VoiceInputBarView.swift    # 음성 입력 바
```

---

## 🎨 디자인 시스템

**색상 팔레트** (`AppTheme.swift`):
- 배경: `#FBF7F4` — 따뜻한 아이보리
- 사용자 말풍선: `#FFE7D6` — 살구색
- 상담사 말풍선: `#F2ECFF` — 연보라
- 텍스트 Primary: `#2B2A33`
- 텍스트 Secondary: `#7A7786`
- 구분선: `#EDE7E1`

**MBTI 테마**: 각 MBTI마다 고유한 파스텔 그래디언트 + 강조색 (16종)

---

## 🔐 스토리지

**SwiftData (로컬 DB)**:
- `ChatSession`: MBTI 코드, 세션 제목, 생성/업데이트 시간, 메시지 목록
- `ChatMessage`: 역할(user/assistant), 내용, 생성 시간, 상위 Session 참조

**AppStorage (UserDefaults)**:
- `defaultInteractionMode`: 기본 입력 모드 (chat / voice)
- `autoPlayTTS`: 자동 TTS 재생 여부
- `hapticsEnabled`: 햅틱 피드백 여부
- `hasShownDisclaimer`: AI 주의사항 팝업 표시 여부 (최초 1회 제어)

---

## ⚙️ 빌드 & 실행

```bash
open SecretMBTICounselor.xcodeproj
```

**최소 요구사항**:
- iOS 26.0+
- Xcode 26.0+
- Apple Silicon Mac (Foundation Models 지원)

**필수 권한 (Info.plist)**:
- `NSMicrophoneUsageDescription` — 음성 입력
- `NSSpeechRecognitionUsageDescription` — 음성 인식

---

## ⚠️ AI 서비스 주의사항

본 앱의 상담사는 사람이 아닌 AI입니다. 전문 심리치료·정신과 진료를 대체하지 않으며, 위기 상황에는 아래 기관에 연락하세요.

- **자살예방상담전화**: 109 (24시간)
- **정신건강위기상담**: 1577-0199 (24시간)
- **청소년전화**: 1388 (24시간)
