では、~/rag-test そのものをまっさらにして、最小構成から組み立て直しましょう。


---

① プロジェクトを空から作り直し
```
# もとのプロジェクトを削除
rm -rf ~/rag-test

# 新しく作り直し
mkdir ~/rag-test
cd ~/rag-test
```

---

② 仮想環境を作成（Python 3.11）

cd ~/rag-test

UV_LINK_MODE=copy uv venv .venv --python 3.11
source .venv/bin/activate


---

③ ライブラリを「安全な組み合わせ」でインストール

NumPy は 2.x ではなく 1.x に固定します。

UV_LINK_MODE=copy uv pip install "numpy<2.0" "faiss-cpu" "fastembed"

これで

numpy 1.26 系

faiss-cpu

fastembed（0.7.3 想定）
が入ります。



---

④ test.sh を作成

cd ~/rag-test
nano test.sh

中身を全部これにしてください。
```
#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

UV_LINK_MODE=copy uv run python - << 'PY'
from fastembed import TextEmbedding
import faiss
import numpy as np

# CPU向けの軽量モデル（デフォルト）
model = TextEmbedding()  # 既定で "BAAI/bge-small-en-v1.5"

sentences = [
    "これはベクトル検索のテストです。",
    "今日はいい天気ですね。",
    "RAGのために文章を埋め込みに変換します。",
]

# 埋め込み生成（ジェネレータ -> list -> ndarray）
emb_list = list(model.embed(sentences))
emb = np.vstack(emb_list).astype("float32")
print("embedding shape:", emb.shape)

# FAISS でインデックス作成
d = emb.shape[1]
index = faiss.IndexFlatL2(d)
index.add(emb)

# クエリ
query = "RAG 用の意味検索をしたい"
q_emb = np.vstack(list(model.embed([query]))).astype("float32")

D, I = index.search(q_emb, 3)

print("query:", query)
for rank, (dist, idx) in enumerate(zip(D[0], I[0]), start=1):
    print(f"Top {rank}: idx={idx}, dist={dist:.4f}, text={sentences[idx]}")
PY
```
保存したら実行権限を付けます。

chmod +x test.sh


---

⑤ 動作確認

まだ source .venv/bin/activate していなければ、もう一度有効化して

cd ~/rag-test
source .venv/bin/activate
bash ./test.sh

うまくいけば

embedding shape: (3, 384) のような行

その下に Top 1〜3 のテキストと距離


が並んで表示されます。

ここまで通れば、rag-test の土台はきれいに再構築できています。
次は、この仕組みにファイル読み込みやインデックス保存を少しずつ足していきましょう。