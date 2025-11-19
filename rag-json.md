🧩 小さなテキストから検索可能な RAG コーパスをつくる

ここでは、テキストファイルを準備し、
それをベクトル化して検索できるようにする一連の流れをご紹介いたします。

構成は、たったの 3 つ。
```
texts/         ← 元テキストファイル群
json_docs/     ← 中間形式（id + text の JSON）
corpus.sqlite  ← メタ情報（id + vector index number）
corpus.index   ← FAISS インデックス
```

---

📌 1. テキストを JSON に変換

次のスクリプトを make_json.py などとして保存します。
```
#!/usr/bin/env python
"""
texts/**.txt → json_docs/**.json
id + text だけの最小 JSON
"""
from pathlib import Path
import json, hashlib

TXT_DIR   = Path("texts")
JSON_DIR  = Path("json_docs")
JSON_DIR.mkdir(parents=True, exist_ok=True)

def make_id(rel_path: Path, text: str) -> str:
    h = hashlib.sha1(text.encode("utf-8")).hexdigest()[:16]
    return f"{rel_path.as_posix()}#{h}"

for txt_path in TXT_DIR.rglob("*.txt"):
    try:
        text = txt_path.read_text(encoding="utf-8", errors="ignore").strip()
    except Exception:
        continue
    if not text:
        continue

    rel = txt_path.relative_to(TXT_DIR)

    rec = {
        "id":   make_id(rel, text),
        "text": text
    }

    out_fp = JSON_DIR / rel.with_suffix(".json")
    out_fp.parent.mkdir(parents=True, exist_ok=True)
    out_fp.write_text(json.dumps(rec, ensure_ascii=False, indent=2), encoding="utf-8")

print("変換完了")
```
🔧 使い方
```
uv run python make_json.py
```
💡 texts/**.txt にあるすべてのテキストが
json_docs/**.json として保存されます。
ファイル名を保持せず、id と text のみが残ります。


---

📌 2. FAISS + SQLite への取り込み（別スクリプト）

通常は、次の処理で以下を作成します。

corpus.jsonl（json_docs を 1 行 1 JSON へ統合）

corpus.sqlite（メタデータ）

corpus.index（ベクトル検索）

続いて、検索用スクリプトを使います。


---

📌 3. 標準入力で検索する

以下を search.py として保存してください。

#!/usr/bin/env python
import sys, json
import sqlite3
import numpy as np
import faiss
from fastembed import TextEmbedding
from pathlib import Path

DB_PATH  = Path("corpus.sqlite")
IDX_PATH = Path("corpus.index")
TOPK     = 3

# ----- query from stdin -----
query = sys.stdin.read().strip()
if not query:
    print(json.dumps({"error": "no query"}, ensure_ascii=False))
    sys.exit(1)

# ----- model -----
model = TextEmbedding()

# ----- load faiss -----
index = faiss.read_index(str(IDX_PATH))

# ----- embed query -----
q_emb = np.vstack(list(model.embed([query]))).astype("float32")
D, I = index.search(q_emb, TOPK)

# ----- get results -----
conn = sqlite3.connect(DB_PATH)
cur  = conn.cursor()

results = []
for idx in I[0]:
    cur.execute("SELECT id, text FROM docs WHERE faiss_idx=?;", (int(idx),))
    row = cur.fetchone()
    if row:
        rid, text = row
        results.append({"id": rid, "text": text})

# ----- output -----
print(json.dumps({"results": results}, ensure_ascii=False, indent=2))

🔍 検索の使い方

echo "意味検索とは？" | uv run python search.py

あるいは、ファイルから：

cat query.txt | uv run python search.py

📌 結果は JSON で返ってきます。

{
  "results": [
    {
      "id": "aaa/bbb.txt#89af3d67a21fdc73",
      "text": "……本文……"
    }
  ]
}


---

🪶 仕上げに

入力は stdin

出力は JSON

データは id と text だけ

インデックス側は FAISS + SQLite