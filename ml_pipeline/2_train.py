"""
2_train.py
klue/bert-base 를 7-class 감정 분류기로 파인튜닝합니다.

출력:
  trained_model/   ← PyTorch 모델 + tokenizer
  processed/label_names.json

사용법: python3 2_train.py
"""

import json
import csv
import torch
import torch.nn as nn
from torch.utils.data import Dataset, DataLoader
from transformers import BertTokenizerFast, BertForSequenceClassification, get_linear_schedule_with_warmup
from pathlib import Path

# ── 설정 ──────────────────────────────────────────────────
MODEL_NAME   = "klue/bert-base"
MAX_LEN      = 128
BATCH_SIZE   = 32
EPOCHS       = 3
LR           = 2e-5
MAX_SAMPLES  = 7000   # 클래스당 최대 샘플 수 (7 × 7000 = 49k, ~30분)
OUT_DIR      = Path("trained_model")
DATA_DIR     = Path("processed")
LABEL_NAMES  = ["기쁨", "슬픔/우울", "불안", "분노", "상처/당황", "중독", "위기"]

OUT_DIR.mkdir(exist_ok=True)

# 디바이스: MPS(Apple Silicon) > CUDA > CPU
if torch.backends.mps.is_available():
    device = torch.device("mps")
    print("디바이스: MPS (Apple Silicon)")
elif torch.cuda.is_available():
    device = torch.device("cuda")
    print("디바이스: CUDA")
else:
    device = torch.device("cpu")
    print("디바이스: CPU")


# ── 데이터셋 ──────────────────────────────────────────────
class EmotionDataset(Dataset):
    def __init__(self, csv_path, tokenizer, max_per_class=None):
        from collections import defaultdict
        import random
        buckets = defaultdict(list)
        with open(csv_path, encoding="utf-8") as f:
            for row in csv.DictReader(f):
                buckets[int(row["label"])].append(row["text"])
        self.items = []
        for label, texts in buckets.items():
            if max_per_class:
                random.seed(42)
                texts = random.sample(texts, min(max_per_class, len(texts)))
            for t in texts:
                self.items.append((t, label))
        random.shuffle(self.items)
        self.tokenizer = tokenizer

    def __len__(self):
        return len(self.items)

    def __getitem__(self, idx):
        text, label = self.items[idx]
        enc = self.tokenizer(
            text,
            max_length=MAX_LEN,
            padding="max_length",
            truncation=True,
            return_tensors="pt",
        )
        return {
            "input_ids":      enc["input_ids"].squeeze(0),
            "attention_mask": enc["attention_mask"].squeeze(0),
            "label":          torch.tensor(label, dtype=torch.long),
        }


# ── 로드 ──────────────────────────────────────────────────
print(f"\n모델 로드 중: {MODEL_NAME}")
tokenizer = BertTokenizerFast.from_pretrained(MODEL_NAME)
model = BertForSequenceClassification.from_pretrained(
    MODEL_NAME,
    num_labels=len(LABEL_NAMES),
    ignore_mismatched_sizes=True,
)
model.to(device)

train_ds = EmotionDataset(DATA_DIR / "train.csv", tokenizer, max_per_class=MAX_SAMPLES)
val_ds   = EmotionDataset(DATA_DIR / "val.csv",   tokenizer, max_per_class=MAX_SAMPLES // 5)
train_dl = DataLoader(train_ds, batch_size=BATCH_SIZE, shuffle=True,  num_workers=0)
val_dl   = DataLoader(val_ds,   batch_size=BATCH_SIZE, shuffle=False, num_workers=0)

print(f"train {len(train_ds)} / val {len(val_ds)} 샘플")


# ── 옵티마이저 ─────────────────────────────────────────────
optimizer = torch.optim.AdamW(model.parameters(), lr=LR, weight_decay=0.01)
total_steps = len(train_dl) * EPOCHS
scheduler = get_linear_schedule_with_warmup(
    optimizer,
    num_warmup_steps=total_steps // 10,
    num_training_steps=total_steps,
)


# ── 학습 루프 ──────────────────────────────────────────────
best_val_acc = 0.0

for epoch in range(1, EPOCHS + 1):
    model.train()
    total_loss = 0.0
    for step, batch in enumerate(train_dl, 1):
        input_ids      = batch["input_ids"].to(device)
        attention_mask = batch["attention_mask"].to(device)
        labels         = batch["label"].to(device)

        optimizer.zero_grad()
        out  = model(input_ids=input_ids, attention_mask=attention_mask, labels=labels)
        loss = out.loss
        loss.backward()
        torch.nn.utils.clip_grad_norm_(model.parameters(), 1.0)
        optimizer.step()
        scheduler.step()

        total_loss += loss.item()
        if step % 50 == 0:
            print(f"  Epoch {epoch} step {step}/{len(train_dl)} loss={total_loss/step:.4f}")

    # 검증
    model.eval()
    correct = total = 0
    with torch.no_grad():
        for batch in val_dl:
            input_ids      = batch["input_ids"].to(device)
            attention_mask = batch["attention_mask"].to(device)
            labels         = batch["label"].to(device)
            logits = model(input_ids=input_ids, attention_mask=attention_mask).logits
            preds = logits.argmax(dim=-1)
            correct += (preds == labels).sum().item()
            total   += labels.size(0)

    val_acc = correct / total
    print(f"Epoch {epoch} — loss={total_loss/len(train_dl):.4f}, val_acc={val_acc:.4f}")

    if val_acc > best_val_acc:
        best_val_acc = val_acc
        model.save_pretrained(OUT_DIR)
        tokenizer.save_pretrained(OUT_DIR)
        print(f"  ✓ 모델 저장 (best val_acc={best_val_acc:.4f})")

# 레이블 이름 저장 (변환 스크립트에서 사용)
with open(DATA_DIR / "label_names.json", "w", encoding="utf-8") as f:
    json.dump(LABEL_NAMES, f, ensure_ascii=False, indent=2)

print(f"\n학습 완료. Best val_acc: {best_val_acc:.4f}")
print("→ trained_model/ 에 모델 저장됨")
