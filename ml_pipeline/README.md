# ML Pipeline — MBTI 상담 프롬프트 감정 분류기

AIHUB 한국어 심리 데이터 3종으로 Core ML 분류기를 학습합니다.

## 실행 순서

```bash
cd ml_pipeline

# 1. 데이터 전처리 (~2분)
python3 1_preprocess.py

# 2. 모델 학습 (~20~60분, Apple Silicon MPS 가속)
python3 2_train.py

# 3. Core ML 변환 (~5분)
python3 3_convert_coreml.py
```

## 출력 파일

| 파일 | 역할 |
|------|------|
| `EmotionClassifier.mlpackage` | Xcode에 드래그 |
| `vocab.txt` | 앱 번들 리소스로 추가 |

## Xcode 통합

1. `EmotionClassifier.mlpackage` → 프로젝트 루트에 드래그 (Copy if needed ✓)
2. `vocab.txt` → 프로젝트에 드래그 (Copy if needed ✓)
3. 빌드 → `PromptContextClassifier` 자동 사용

## 레이블 (7-class)

| ID | 이름 | 데이터 출처 |
|----|------|------------|
| 0 | 기쁨 | 감성대화 E01-E03 |
| 1 | 슬픔/우울 | 감성대화 E14-E18 + 심리상담 DEPRESSION |
| 2 | 불안 | 감성대화 E09-E11 + 심리상담 ANXIETY |
| 3 | 분노 | 감성대화 E06-E08 |
| 4 | 상처/당황 | 감성대화 E04-E05, E12-E13 |
| 5 | 중독 | 심리상담 ADDICTION |
| 6 | 위기 | 아동·청소년 학대의심/위기 |

## 파이프라인 흐름

```
사용자 메시지
  ↓ Stage 0: Core ML 감정 분류 (on-device, <10ms)
  감정 레이블 + 확률 → promptContext 문자열 생성
  ↓ Stage 1: FoundationModels 의도 분류 (감정 컨텍스트 주입)
  ↓ Stage 2: 3개 후보 병렬 생성 (각각 감정 컨텍스트 주입)
  ↓ Stage 3: 합성
  ↓ Stage 4: 검증 + 재생성
  최종 답변
```
