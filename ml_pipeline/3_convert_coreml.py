"""
3_convert_coreml.py
파인튜닝된 klue/bert-base 를 Core ML (.mlpackage) 로 변환합니다.

출력:
  EmotionClassifier.mlpackage  ← Xcode에 드래그해서 추가
  vocab.txt                    ← Swift 앱 번들에 포함

사용법: python3 3_convert_coreml.py
"""

import json
import shutil
import numpy as np
import torch
import torch.nn as nn
import coremltools as ct
from transformers import BertForSequenceClassification
from pathlib import Path

MODEL_DIR   = Path("trained_model")
DATA_DIR    = Path("processed")
OUT_PATH    = Path("EmotionClassifier.mlpackage")
MAX_LEN     = 128

# ── 레이블 로드 ────────────────────────────────────────────
with open(DATA_DIR / "label_names.json", encoding="utf-8") as f:
    label_names = json.load(f)

print("레이블:", label_names)


# ── Softmax 포함 래퍼 ──────────────────────────────────────
# Core ML 쪽에서 확률값을 바로 읽을 수 있도록 softmax 내장
class TracableWrapper(nn.Module):
    def __init__(self, bert):
        super().__init__()
        self.bert = bert

    def forward(self, input_ids: torch.Tensor, attention_mask: torch.Tensor):
        logits = self.bert(input_ids=input_ids, attention_mask=attention_mask).logits
        return torch.softmax(logits, dim=-1)


print("모델 로드 중...")
base = BertForSequenceClassification.from_pretrained(MODEL_DIR)
base.eval()

wrapper = TracableWrapper(base)
wrapper.eval()

# ── 트레이싱 ───────────────────────────────────────────────
dummy_ids  = torch.zeros(1, MAX_LEN, dtype=torch.long)
dummy_mask = torch.ones(1,  MAX_LEN, dtype=torch.long)

print("torch.jit.trace 중...")
with torch.no_grad():
    traced = torch.jit.trace(wrapper, (dummy_ids, dummy_mask), strict=False)

# 정상 출력 확인
sample_out = traced(dummy_ids, dummy_mask)
print(f"출력 shape: {sample_out.shape}, sum={sample_out.sum().item():.4f}")


# ── Core ML 변환 ───────────────────────────────────────────
print("Core ML 변환 중...")

mlmodel = ct.convert(
    traced,
    inputs=[
        ct.TensorType(name="input_ids",      shape=(1, MAX_LEN), dtype=np.int32),
        ct.TensorType(name="attention_mask",  shape=(1, MAX_LEN), dtype=np.int32),
    ],
    outputs=[
        ct.TensorType(name="probabilities"),
    ],
    minimum_deployment_target=ct.target.iOS17,
    compute_units=ct.ComputeUnit.ALL,
)

# 메타데이터
mlmodel.short_description = "MBTI 상담 프롬프트 감정 분류기 (AIHUB 한국어 심리 데이터 학습)"
mlmodel.input_description["input_ids"]     = "토크나이저 출력 token ID 시퀀스 (길이 128)"
mlmodel.input_description["attention_mask"] = "패딩 마스크 (1=유효, 0=패딩)"
mlmodel.output_description["probabilities"] = f"7-class 감정 확률 {label_names}"

for i, name in enumerate(label_names):
    mlmodel.user_defined_metadata[f"label_{i}"] = name

# ── 저장 ──────────────────────────────────────────────────
if OUT_PATH.exists():
    shutil.rmtree(OUT_PATH)
mlmodel.save(str(OUT_PATH))

# vocab.txt 복사 (Swift 토크나이저에서 사용)
shutil.copy(MODEL_DIR / "vocab.txt", "vocab.txt")

print(f"\n✓ {OUT_PATH} 저장 완료")
print("✓ vocab.txt 복사 완료")
print("\n다음 단계:")
print("  1. EmotionClassifier.mlpackage → Xcode 프로젝트에 드래그")
print("  2. vocab.txt → Xcode 프로젝트 리소스에 추가")
