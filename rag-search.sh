#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

: "${UV_LINK_MODE:=copy}"

UV_LINK_MODE="$UV_LINK_MODE" uv run python - << 'PY'
from pathlib import Path
import sqlite3, json, sys
import faiss, numpy as np
from fastembed import TextEmbedding

# ------------------ 設定 ------------------
CORPUS_PATH = Path("corpus.jsonl")      # 入力コーパス (1行1JSON: {id, text})
DB_PATH     = Path("corpus.sqlite")     # SQLite にメタデータ格納
IDX_PATH    = Path("corpus.index")      # FAISS バイナリ
MODEL_NAME  = None                      # None なら fastembed 既定
# ------------------------------------------

# ---------- 1. SQLite 準備 ----------
conn = sqlite3.connect(DB_PATH)
cur  = conn.cursor()
cur.execute("""
CREATE TABLE IF NOT EXISTS docs(
    id        TEXT    PRIMARY KEY,
    faiss_idx INTEGER UNIQUE,
    text      TEXT
);
""")
cur.execute("CREATE INDEX IF NOT EXISTS idx_faiss ON docs(faiss_idx);")
conn.commit()

# ---------- 2. 既存メタ情報取得 ----------
cur.execute("SELECT id, faiss_idx FROM docs;")
rows = cur.fetchall()
indexed_ids  = {r[0]: r[1] for r in rows}         # id -> faiss_idx
next_idx     = 0 if not rows else max(r[1] for r in rows) + 1
print(f"インデックス済み件数: {len(indexed_ids)} (次の idx = {next_idx})")

# ---------- 3. 既存 FAISS インデックス確認 ----------
need_full_rebuild = False
if IDX_PATH.exists():
    index = faiss.read_index(str(IDX_PATH))
    if index.ntotal != len(indexed_ids):
        print("WARNING: FAISS と SQLite が不整合。フル再構築します。")
        need_full_rebuild = True
else:
    need_full_rebuild = True

# ---------- 4. コーパス読み込み ----------
if not CORPUS_PATH.exists():
    sys.exit(f"ERROR: {CORPUS_PATH} が見つかりません")

all_records = []
with CORPUS_PATH.open(encoding="utf-8") as f:
    for ln_no, line in enumerate(f, 1):
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
        except json.JSONDecodeError as e:
            sys.exit(f"JSONL パースエラー (行 {ln_no}): {e}")
        if "id" not in obj or "text" not in obj:
            sys.exit(f"行 {ln_no}: 'id' と 'text' が必須です")
        all_records.append(obj)

if not all_records:
    print("注意: corpus.jsonl が空です。空インデックスのまま終了します。")
    # 一応中身をクリアしておく
    cur.execute("DELETE FROM docs;")
    conn.commit()
    if IDX_PATH.exists():
        IDX_PATH.unlink()
    sys.exit(0)

corpus_ids_set = {r["id"] for r in all_records}

# corpus から削除された id が SQLite に残っていればフル再構築
if any(i not in corpus_ids_set for i in indexed_ids):
    print("WARNING: corpus から削除された id が検出されました。フル再構築します。")
    need_full_rebuild = True

# ---------- 5. 埋め込みモデル ----------
model = TextEmbedding(model_name=MODEL_NAME) if MODEL_NAME else TextEmbedding()

# ---------- 6A. フル再構築 ----------
if need_full_rebuild:
    print("フル再構築中 …")
    texts = [r["text"] for r in all_records]
    emb   = np.vstack(list(model.embed(texts))).astype("float32")
    d     = emb.shape[1]
    index = faiss.IndexFlatL2(d)
    index.add(emb)
    faiss.write_index(index, str(IDX_PATH))

    # SQLite を再生成
    cur.execute("DELETE FROM docs;")
    cur.executemany(
        "INSERT INTO docs(id, faiss_idx, text) VALUES (?,?,?)",
        [(r["id"], idx, r["text"]) for idx, r in enumerate(all_records)]
    )
    conn.commit()
    print(f"再構築完了: ntotal={index.ntotal}")

# ---------- 6B. 差分追加 ----------
else:
    new_records = [r for r in all_records if r["id"] not in indexed_ids]
    if not new_records:
        print("差分なし。")
    else:
        print(f"新規 {len(new_records)} 件の埋め込みを追加 …")
        new_texts = [r["text"] for r in new_records]
        new_emb   = np.vstack(list(model.embed(new_texts))).astype("float32")
        index.add(new_emb)
        faiss.write_index(index, str(IDX_PATH))

        # SQLite へ追記
        cur.executemany(
            "INSERT INTO docs(id, faiss_idx, text) VALUES (?,?,?)",
            [
                (r["id"], next_idx + i, r["text"])
                for i, r in enumerate(new_records)
            ]
        )
        conn.commit()
        print(f"追加完了: ntotal={index.ntotal}")
PY