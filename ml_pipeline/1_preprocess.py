"""
1_preprocess.py
세 AIHUB 데이터셋을 파싱해 7-class 통합 레이블 CSV를 생성합니다.

출력 레이블 (7개):
  0: 기쁨     - 긍정/안도/사랑
  1: 슬픔/우울 - 슬픔/실망/후회/우울증
  2: 불안     - 불안/두려움/스트레스
  3: 분노     - 분노/경멸/혐오
  4: 상처/당황 - 상처/질투/당황/놀람
  5: 중독     - 중독 패턴
  6: 위기     - 학대의심/위기 상황

사용법: python3 1_preprocess.py
"""

import json
import zipfile
import re
import csv
import random
from pathlib import Path

DATA_DIR = Path("../dataFromAIHUB")
OUT_DIR = Path("processed")
OUT_DIR.mkdir(exist_ok=True)

LABELS = ["기쁨", "슬픔/우울", "불안", "분노", "상처/당황", "중독", "위기"]

# 감성대화 E코드 → 통합 레이블 매핑
# 실제 데이터: E10~E69 (60종). AIHUB 감성대화 6대분류 × 10소분류 추정.
EMOTION_MAP: dict[str, int] = {}
for _i in range(10, 20): EMOTION_MAP[f"E{_i}"] = 0   # 기쁨
for _i in range(20, 30): EMOTION_MAP[f"E{_i}"] = 4   # 당황
for _i in range(30, 40): EMOTION_MAP[f"E{_i}"] = 3   # 분노
for _i in range(40, 50): EMOTION_MAP[f"E{_i}"] = 2   # 불안
for _i in range(50, 60): EMOTION_MAP[f"E{_i}"] = 4   # 상처
for _i in range(60, 70): EMOTION_MAP[f"E{_i}"] = 1   # 슬픔

# 심리상담 class → 통합 레이블 매핑
COUNSELING_MAP = {
    "DEPRESSION": 1,
    "ANXIETY":    2,
    "ADDICTION":  5,
    "GENERAL":    4,  # 일반군: 일반 어려움 → 상처/당황으로 처리
}

samples = []


def add(text: str, label: int):
    text = text.strip()
    if len(text) < 5:
        return
    samples.append({"text": text, "label": label})


# ──────────────────────────────────────────────────────────
# Dataset 1: 018.감성대화
# ──────────────────────────────────────────────────────────
print("[1/3] 감성대화 처리 중...")

for zip_path in sorted((DATA_DIR / "018.감성대화").rglob("*.zip")):
    if "라벨링" not in str(zip_path):
        continue
    try:
        with zipfile.ZipFile(zip_path) as zf:
            for name in zf.namelist():
                if not name.endswith(".json"):
                    continue
                raw = zf.read(name).decode("utf-8", errors="ignore")
                data = json.loads(raw)
                items = data if isinstance(data, list) else [data]
                for item in items:
                    emotion_id = (
                        item.get("profile", {})
                            .get("emotion", {})
                            .get("type", "")
                    )
                    label = EMOTION_MAP.get(emotion_id)
                    if label is None:
                        continue
                    talk = item.get("talk", {}).get("content", {})
                    for key in ["HS01", "HS02", "HS03"]:
                        add(talk.get(key, ""), label)
    except Exception as e:
        print(f"  skip {zip_path.name}: {e}")

print(f"  감성대화 샘플 수: {len(samples)}")


# ──────────────────────────────────────────────────────────
# Dataset 2: 16.심리상담 데이터
# ──────────────────────────────────────────────────────────
print("[2/3] 심리상담 처리 중...")
before = len(samples)

for zip_path in sorted((DATA_DIR / "16.심리상담 데이터").rglob("*.zip")):
    if "라벨링" not in str(zip_path) and "02.라벨링" not in str(zip_path):
        continue
    try:
        with zipfile.ZipFile(zip_path) as zf:
            for name in zf.namelist():
                if not name.endswith(".json"):
                    continue
                raw = zf.read(name).decode("utf-8", errors="ignore")
                session = json.loads(raw)
                cls = session.get("class", "").upper()
                label = COUNSELING_MAP.get(cls)
                if label is None:
                    continue
                for para in session.get("paragraph", []):
                    if para.get("paragraph_speaker") == "내담자":
                        text = str(para.get("paragraph_text") or "")
                        text = re.sub(r"@\w+", "", text)  # @ETC 같은 태그 제거
                        add(text, label)
    except Exception as e:
        print(f"  skip {zip_path.name}: {e}")

print(f"  심리상담 샘플 수: {len(samples) - before}")


# ──────────────────────────────────────────────────────────
# Dataset 3: 024.아동·청소년 상담 데이터
# ──────────────────────────────────────────────────────────
print("[3/3] 아동·청소년 처리 중...")
before = len(samples)

CRISIS_LABEL_MAP = {
    "학대의심": 6,
    "위기":    6,
    "상담필요": 2,  # 불안 수준으로 처리
    "일반":    0,
}

for zip_path in sorted((DATA_DIR / "024.아동·청소년 상담 데이터").rglob("*.zip")):
    try:
        with zipfile.ZipFile(zip_path) as zf:
            for name in zf.namelist():
                if not name.endswith(".json"):
                    continue
                raw = zf.read(name).decode("utf-8", errors="ignore")
                session = json.loads(raw)
                crisis = session.get("info", {}).get("위기단계", "")
                label = None
                for key, val in CRISIS_LABEL_MAP.items():
                    if key in crisis:
                        label = val
                        break
                if label is None:
                    continue
                for section in session.get("list", []):
                    for item in section.get("list", []):
                        for audio in item.get("audio", []):
                            if audio.get("type") == "A":
                                add(audio.get("text", ""), label)
    except Exception as e:
        print(f"  skip {zip_path.name}: {e}")

print(f"  아동·청소년 샘플 수: {len(samples) - before}")


# ──────────────────────────────────────────────────────────
# 저장 & 통계
# ──────────────────────────────────────────────────────────
random.seed(42)
random.shuffle(samples)

split = int(len(samples) * 0.9)
train, val = samples[:split], samples[split:]

def save_csv(path, rows):
    with open(path, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=["text", "label"])
        w.writeheader()
        w.writerows(rows)

save_csv(OUT_DIR / "train.csv", train)
save_csv(OUT_DIR / "val.csv", val)

print(f"\n총 샘플: {len(samples)} (train {len(train)} / val {len(val)})")
print("\n레이블 분포:")
from collections import Counter
cnt = Counter(s["label"] for s in samples)
for i, name in enumerate(LABELS):
    print(f"  {i} {name}: {cnt[i]}")
print(f"\n→ processed/train.csv, processed/val.csv 저장 완료")
