# ローカル RAG 用コーパス & ベクトル検索スクリプト集

ローカルのテキストファイル群を

- コーパス JSONL
- FAISS ベクトルインデックス
- llama.cpp 用の RAG 入力

まで一気に作るためのスクリプトたちです。

```txt
texts/            … 素のテキスト郡
 ├ foo.txt
 └ docs/bar.md

make-json.py      … texts/ → json_docs/ と corpus.jsonl
db-build.sh       … corpus.jsonl → corpus.sqlite + corpus.index
rag-search.sh     … クエリ → 近傍 id→text 辞書 (JSON)
exec-llama-json-rag.sh
                  … プロンプト + RAG + ファイル群 → llama-cli
```
全体フロー

ざっくり流れはこうなります。

(1) コーパス作成

texts/ 配下のファイル
        |
        v
+-----------------+
|  make-json.py   |
+-----------------+
        |
        +--> json_docs/<同じパス>.json
        |
        +--> corpus.jsonl (1行1JSON: {id, text})


(2) ベクトルインデックス構築

corpus.jsonl
      |
      v
+-------------+
| db-build.sh |
+-------------+
      |
      +--> corpus.sqlite (id, text, faiss_idx)
      +--> corpus.index  (FAISS)


(3) 実行時 RAG + LLM

ユーザの質問(プロンプト)
      |
      v
+-------------+        +------------------+
| rag-search  | -----> |  id→text の辞書  |
+-------------+        +------------------+
          \                 ^
           \                |
            v               |
   +------------------------+----------+
   | exec-llama-json-rag.sh          |
   |  main_prompt + RAG_DB + files   |
   +------------------------+----------+
                             |
                             v
                        +---------+
                        | llama   |
                        | (llama-cli) 
                        +---------+

必要環境

Python 3.11 目安

uv（uv run を使用）

Python ライブラリ

fastembed

faiss-cpu

numpy


CLI ツール

bash

jq

file

sqlite3（デバッグ時など）


llama.cpp の llama-cli バイナリ（パスが通っているか、もしくは LLAMA_CLI で指定）


ディレクトリ構成（例）

project-root/
 ├ texts/                … インデックスしたいテキスト
 ├ json_docs/            … make-json.py が作成
 ├ corpus.jsonl          … make-json.py が作成
 ├ corpus.sqlite         … db-build.sh が作成
 ├ corpus.index          … db-build.sh が作成
 ├ make-json.py
 ├ db-build.sh
 ├ rag-search.sh
 ├ exec-llama-json-rag.sh
 └ prompt/
     └ prompt.txt        … llama 用システムプロンプト等

使い方ざっくり

1. texts/ にテキストファイルを置く


2. コーパス JSONL & 個別 JSON を作成

python make-json.py


3. ベクトルインデックスを構築

./db-build.sh


4. ベクトル検索だけ試す

echo "検索したい内容" | ./rag-search.sh


5. LLM + RAG でまとめて実行（例：texts/ 配下の .txt を順番に処理）

echo "このコーパスから◯◯について教えて" \
  | ./exec-llama-json-rag.sh -d texts -r --ext .txt -- --temp 0.2

-- より後ろは llama-cli にそのまま渡されます。




---

make-json.py : texts/ から JSON と JSONL を作る

役割

texts/ 以下の「読めるファイル」を全部なめて

json_docs/<同じパス>.json として 1 ファイル 1 JSON に

corpus.jsonl に 1 行 1 レコード（{id, text}）で追記


id は「相対パス + 内容ハッシュ」で一意になるようにしています。


スクリプト全文

#!/usr/bin/env python
"""
texts/ 以下の“読める”ファイルをすべて
  1. json_docs/<同じパス>.json  … 個別の JSON
  2. corpus.jsonl               … 1 行 1 JSON のまとめ
へ変換して保存
"""
from pathlib import Path
import json, hashlib, tempfile, os, shutil

TXT_DIR   = Path("texts")
JSON_DIR  = Path("json_docs")
JSONL_FP  = Path("corpus.jsonl")       # まとめて書き出す先
JSON_DIR.mkdir(parents=True, exist_ok=True)

def make_id(rel_path: Path, text: str) -> str:
    h = hashlib.sha1(text.encode("utf-8")).hexdigest()[:16]
    return f"{rel_path.as_posix()}#{h}"

# -------- jsonl を一旦テンポラリに書き出す --------
with tempfile.NamedTemporaryFile("w", delete=False, encoding="utf-8") as jf:
    temp_jsonl = Path(jf.name)         # 終了時に rename する
    for fp in TXT_DIR.rglob("*"):
        if fp.is_dir():
            continue

        try:
            text = fp.read_text(encoding="utf-8", errors="ignore").strip()
        except Exception:
            continue                   # 読めないファイルはスキップ
        if not text:
            continue                   # 空ファイルもスキップ

        rel = fp.relative_to(TXT_DIR)
        rec = {
            "id":   make_id(rel, text),
            "text": text
        }

        # 1) 個別 JSON
        out_fp = JSON_DIR / rel.with_suffix(".json")
        out_fp.parent.mkdir(parents=True, exist_ok=True)
        out_fp.write_text(
            json.dumps(rec, ensure_ascii=False, indent=2),
            encoding="utf-8"
        )

        # 2) JSONL に書き込み（1 行 1 JSON, 改行区切り, インデント無し）
        jf.write(json.dumps(rec, ensure_ascii=False) + "\n")

# 完了したら atomically 置き換え
temp_jsonl.replace(JSONL_FP)

print(f"変換完了: 個別 JSON → {JSON_DIR}/, まとめ → {JSONL_FP}")

ポイント

TXT_DIR.rglob("*") なので拡張子は問わず、「読めるテキスト」ならなんでも対象です。

errors="ignore" で壊れた文字も無視して読み込み。

JSONL は一度テンポラリファイルに書き出してから replace() しているので、 途中で落ちても corpus.jsonl が中途半端な状態になりにくくなっています。



---

db-build.sh : corpus.jsonl から FAISS + SQLite を作る

役割

corpus.jsonl（1行1レコード {id,text}）を読み込み

fastembed で埋め込みを計算

FAISS に登録して corpus.index として保存

メタ情報（id, faiss_idx, text）を corpus.sqlite に保存

既存 DB がある場合は差分追加にも対応（※不整合があるときはフル再構築）


スクリプト全文

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

ポイント

既存の corpus.sqlite / corpus.index がある場合は

ドキュメント数に不整合があればフル再構築

corpus.jsonl の方から削除された id があってもフル再構築


問題なければ「新しい id だけ追加」する差分モードで高速に更新できます。

MODEL_NAME に fastembed のモデル名を入れると差し替え可能です。



---

rag-search.sh : クエリから近傍ドキュメントを取り出す

役割

標準入力または引数からクエリ文字列を受け取る

fastembed でクエリをベクトル化

corpus.index に対して FAISS 検索

corpus.sqlite から id ごとの本文を引いてきて

id → text な辞書を JSON で出力します。


スクリプト全文

#!/usr/bin/env bash
# rag-search.sh : ベクトル検索 → id ➔ text の辞書を JSON で返す
set -euo pipefail
cd "$(dirname "$0")"

: "${UV_LINK_MODE:=copy}"      # uv run のリンクモード既定値

# ---------- クエリ取得 ----------
if [[ $# > 0 ]]; then
  query="$*"
else
  read -r query || true
fi

if [[ -z "${query:-}" ]]; then
  echo '{"error":"no query"}'
  exit 1
fi

# ---------- Python 実行 ----------
UV_LINK_MODE="$UV_LINK_MODE" QUERY="$query" \
uv run python - <<'PY'
import os, sys, json, sqlite3
from pathlib import Path
import numpy as np, faiss
from fastembed import TextEmbedding

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
else:
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

# ------------------ 設定 (ビルド側と同じ) ------------------
DB_PATH    = Path("corpus.sqlite")   # SQLite DB
IDX_PATH   = Path("corpus.index")    # FAISS インデックス
TOPK       = 3                       # 取得件数
MODEL_NAME = None                    # ビルドスクリプトと同じ変数を使用
# ----------------------------------------------------------

# クエリ取得
query = os.environ.get("QUERY", "").strip()
if not query:
    print(json.dumps({"error": "no query"}, ensure_ascii=False))
    sys.exit(1)

# ---------- ファイル存在チェック ----------
if not DB_PATH.exists() or not IDX_PATH.exists():
    print(json.dumps(
        {"error": "corpus.sqlite または corpus.index が見つかりません"},
        ensure_ascii=False))
    sys.exit(1)

# ---------- 埋め込みモデル (ビルド時と同一設定) ----------
model = TextEmbedding(model_name=MODEL_NAME) if MODEL_NAME else TextEmbedding()

# ---------- FAISS インデックス読み込み ----------
index = faiss.read_index(str(IDX_PATH))

# ---------- クエリを埋め込み ----------
q_emb = np.vstack(list(model.embed([query]))).astype("float32")
D, I  = index.search(q_emb, TOPK)

# ---------- SQLite から本文取得 ----------
conn = sqlite3.connect(DB_PATH)
cur  = conn.cursor()

dictionary = {}
for faiss_idx in I[0]:
    if faiss_idx < 0:      # ヒットなしの場合
        continue
    cur.execute("SELECT id, text FROM docs WHERE faiss_idx=?;", (int(faiss_idx),))
    row = cur.fetchone()
    if row:
        rid, text = row
        dictionary[rid] = text

# ---------- 出力 ----------
print(json.dumps({"DB": dictionary}, ensure_ascii=False, indent=2))
PY

ポイント

出力は

{
  "DB": {
    "path/to/file.txt#deadbeef": "……本文……",
    "another/file.md#12345678": "……本文……"
  }
}

のような形です。

TOPK を変えれば検索件数を調整できます（環境変数ではなく、スクリプト内定数）。



---

exec-llama-json-rag.sh : プロンプト + RAG + ファイル群を llama-cli へ渡す

役割

標準入力からメインプロンプトを受け取る（なければ空）

rag-search.sh を呼び出して、プロンプトに関連するコーパス断片を取得

コマンドラインで指定されたファイル/ディレクトリ内のテキストファイルを読み込む

それらをまとめた JSON を一時ファイルに書き出し、そのファイルを llama-cli -f で食べさせます


生成する JSON のイメージ：

{
  "main_prompt": "ユーザからの依頼本文",
  "DB": { "...": "RAG 用の参考テキスト", "...": "..." },
  "files": [
    { "path": "path/to/file1.txt", "text": "……内容……" },
    { "path": "path/to/file2.txt", "text": "……内容……" }
  ]
}

スクリプト全文

#!/usr/bin/env bash
# exec-llama-json-rag.sh  (MSYS + RAG 改善版, DB は JSON オブジェクト)

set -euo pipefail
shopt -s globstar nullglob

#------------------------------------------------------------
# 0. 既定値（環境変数で上書き可）
#------------------------------------------------------------
# MSYS2/MinGW の暗黙パス変換・コードページ変換を抑制したい場合は必要に応じて有効化
# export MSYS2_ARG_CONV_EXCL='*'
export LC_ALL=C.UTF-8

LLAMA_CLI="${LLAMA_CLI:-llama-cli}"
MODEL="${MODEL:-\
./models/Qwen3-VL-8B-Instruct-IQ4_NL.gguf}"
CTX="${CTX:-4096}"
BATCH="${BATCH:-512}"
N_PREDICT="${N_PREDICT:--1}"
SEED="${SEED:--1}"
MAINGPU="${MAINGPU:-0}"
NGL="${NGL:-999}"
SYS_FILE="${SYS_FILE:-./prompt/prompt.txt}"

# ---- RAG 関連 ----
# bash 経由で呼び出すため配列で保持
RAG_CMD=(${RAG_CMD:-bash ./rag-search.sh})
RAG_TOPK="${RAG_TOPK:-}"
# ------------------

PROMPT_CACHE="${PROMPT_CACHE:-}"
TIMEOUT_SEC="${TIMEOUT_SEC:-}"
MAX_INPUT_BYTES="${MAX_INPUT_BYTES:-1048576}"
SKIP_BINARY_CHECK="${SKIP_BINARY_CHECK:-0}"

#------------------------------------------------------------
# 1. 収集オプション
#------------------------------------------------------------
RECURSIVE=false
EXT=""
PAIRWISE_MODE=false

#------------------------------------------------------------
# 2. 内部変数
#------------------------------------------------------------
declare -a TARGETS=()
declare -a LL_EXTRA_ARGS=()

# RAG からの参考情報（id → text）の JSON オブジェクト文字列
RAG_DB_JSON='{}'

#------------------------------------------------------------
# 3. ヘルプ
#------------------------------------------------------------
usage() {
  cat <<'EOS'
Usage:
  echo "PROMPT" | exec-llama-json-rag.sh [opts] <PATH …> [-- llama-cli-opts]

  -d <DIR …>  : ディレクトリを対象にする
  -f <FILE …> : 個別ファイルを対象にする
  -r          : ディレクトリを再帰探索
  --ext .txt  : 拡張子フィルタ (例: .txt)
  -p, --pairwise : ディレクトリ間のペアワイズ比較モード
  -h, --help  : このヘルプ

  それ以降の引数は -- で区切って llama-cli にそのまま渡されます。
EOS
}

#------------------------------------------------------------
# 4. オプション解析
#------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case $1 in
    -d)
      shift
      while [[ $# -gt 0 && ! $1 =~ ^- ]]; do
        TARGETS+=("$1")
        shift
      done
      ;;
    -f)
      shift
      while [[ $# -gt 0 && ! $1 =~ ^- ]]; do
        TARGETS+=("$1")
        shift
      done
      ;;
    -r)
      RECURSIVE=true
      shift
      ;;
    --ext)
      EXT="$2"
      shift 2
      ;;
    -p|--pairwise)
      PAIRWISE_MODE=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      LL_EXTRA_ARGS+=("$@")
      break
      ;;
    -*)
      echo "不明なオプション: $1" >&2
      usage
      exit 1
      ;;
    *)
      TARGETS+=("$1")
      shift
      ;;
  esac
done

#------------------------------------------------------------
# 5. メインプロンプト取得
#------------------------------------------------------------
if [ -t 0 ]; then
  MAIN_PROMPT=""
else
  MAIN_PROMPT=$(cat)
  # 末尾の余計な改行だけ落とす（中の改行はそのまま）
  MAIN_PROMPT="$(printf '%s' "$MAIN_PROMPT")"
fi

#------------------------------------------------------------
# 5.5 RAG 追加コンテキスト（DB は dictionary のまま利用）
#------------------------------------------------------------
if [[ -n $MAIN_PROMPT ]]; then
  if ! command -v "${RAG_CMD[0]}" >/dev/null 2>&1; then
    echo "warn: RAG 無効 (${RAG_CMD[*]} が見つかりません)" >&2
  else
    rag_tmp=$(mktemp)

    # RAG 実行結果を一時ファイルに直接保存（UTF-8 のまま）
    if [[ -n $RAG_TOPK ]]; then
      "${RAG_CMD[@]}" --topk "$RAG_TOPK" <<<"$MAIN_PROMPT" >"$rag_tmp" 2>/dev/null || true
    else
      "${RAG_CMD[@]}"            <<<"$MAIN_PROMPT" >"$rag_tmp" 2>/dev/null || true
    fi

    # .dictionary をそのまま JSON オブジェクトとして取り込む
    # 失敗した場合や存在しない場合は {} にフォールバック
    if ! RAG_DB_JSON=$(jq '.dictionary // {}' "$rag_tmp" 2>/dev/null); then
      RAG_DB_JSON='{}'
    fi

    rm -f "$rag_tmp"
  fi
fi

#------------------------------------------------------------
# 6. 依存コマンド確認
#------------------------------------------------------------
for c in jq file "$LLAMA_CLI"; do
  command -v "$c" >/dev/null 2>&1 || { echo "need '$c'" >&2; exit 127; }
done

#------------------------------------------------------------
# 7. バイナリ判定
#------------------------------------------------------------
is_binary() { [[ $(file --brief --mime-type "$1") != text/* ]]; }

#------------------------------------------------------------
# 8. ファイル収集
#------------------------------------------------------------
declare -a FILES=()
for p in "${TARGETS[@]}"; do
  if [[ -d $p ]]; then
    depth_opt=$($RECURSIVE && echo "" || echo "-maxdepth 1")
    mapfile -t cand < <(find "$p" $depth_opt -type f ${EXT:+-name "*$EXT"} | sort)
  elif [[ -f $p ]]; then
    cand=("$p")
  else
    echo "警告: 無効パス $p" >&2
    continue
  fi

  for f in "${cand[@]}"; do
    if [[ $SKIP_BINARY_CHECK -eq 0 ]] && is_binary "$f"; then
      echo "skip binary: $f" >&2
      continue
    fi
    FILES+=("$f")
  done
done

#------------------------------------------------------------
# 9. llama-cli 共通引数
#------------------------------------------------------------
LL_ARGS=(
  -m "$MODEL" --no-warmup --simple-io -st
  -c "$CTX"   -b "$BATCH"   -n "$N_PREDICT" --seed "$SEED"
  -ngl "$NGL" --main-gpu "$MAINGPU"
)
[[ -f $SYS_FILE     ]] && LL_ARGS+=( -sysf "$SYS_FILE" )
[[ -n $PROMPT_CACHE ]] && LL_ARGS+=( --prompt-cache "$PROMPT_CACHE" )

#------------------------------------------------------------
#10. JSON 生成・実行
#------------------------------------------------------------
json_escape() {
  printf '%s' "$1" | jq -Rs .
}

run_llama() {
  local files=("$@")
  local tmp; tmp=$(mktemp)
  # run_llama 内だけでクリーンアップ
  trap 'rm -f "$tmp"' RETURN

  {   # JSON 出力
    echo '{'
    printf '  "main_prompt": %s,\n' "$(json_escape "$MAIN_PROMPT")"
    printf '  "DB": %s,\n'          "$RAG_DB_JSON"
    echo '  "files": ['
    local first=true
    for f in "${files[@]}"; do
      [[ -z $f ]] && continue
      if $first; then
        first=false
      else
        echo ','
      fi
      txt=$(<"$f")
      printf '    { "path": %s, "text": %s }' \
             "$(json_escape "$f")" "$(json_escape "$txt")"
    done
    echo
    echo '  ]'
    echo '}'
  } >"$tmp"

  if [[ -n $MAX_INPUT_BYTES ]] && [[ $(wc -c <"$tmp") -gt $MAX_INPUT_BYTES ]]; then
    echo "input too large: ${files[*]}" >&2
    return
  fi

  if [[ -n $TIMEOUT_SEC ]]; then
    timeout --preserve-status --kill-after=2s "${TIMEOUT_SEC}s" \
      "$LLAMA_CLI" "${LL_ARGS[@]}" "${LL_EXTRA_ARGS[@]}" -f "$tmp"
  else
    "$LLAMA_CLI" "${LL_ARGS[@]}" "${LL_EXTRA_ARGS[@]}" -f "$tmp"
  fi
}

#------------------------------------------------------------
#11. 実行（単純モード）
#------------------------------------------------------------
if ((${#FILES[@]} == 0)); then
  run_llama
  exit
fi

if ! $PAIRWISE_MODE; then
  for f in "${FILES[@]}"; do
    run_llama "$f"
  done
  exit
fi

#------------------------------------------------------------
#12. ペアワイズ実行ロジック
#------------------------------------------------------------
if ((${#FILES[@]} < 2)); then
  echo "pairwise 実行には 2 つ以上のファイルが必要です" >&2
  exit 2
fi

declare -A DIR2FILES
for f in "${FILES[@]}"; do
  dir=$(dirname "$f")
  DIR2FILES["$dir"]+="${DIR2FILES[$dir]:+$'\n'}$f"
done
dirs=("${!DIR2FILES[@]}")

for ((i=0; i<${#dirs[@]}-1; i++)); do
  for ((j=i+1; j<${#dirs[@]}; j++)); do
    mapfile -t left  <<<"${DIR2FILES[${dirs[i]}]}"
    mapfile -t right <<<"${DIR2FILES[${dirs[j]}]}"
    for l in "${left[@]}";  do
      [[ -z $l ]] && continue
      for r in "${right[@]}"; do
        [[ -z $r ]] && continue
        run_llama "$l" "$r"
      done
    done
  done
done

主なオプションと環境変数

環境変数

LLAMA_CLI : llama-cli のパス

MODEL : 使用する GGUF モデル

CTX, BATCH, N_PREDICT, SEED, MAINGPU, NGL : llama.cpp 側の各種パラメータ

SYS_FILE : システムプロンプトファイル

PROMPT_CACHE : llama.cpp のプロンプトキャッシュファイル

TIMEOUT_SEC : llama-cli 実行のタイムアウト秒数

MAX_INPUT_BYTES : 1 回の JSON 入力サイズ上限


実行オプション

-d <DIR> : ディレクトリを対象に

-f <FILE> : 個別ファイルを対象に

-r : ディレクトリを再帰的にたどる

--ext .txt : 拡張子フィルタ

-p, --pairwise : ディレクトリ間ペアワイズ比較モード

-- 以降 : llama-cli にそのまま渡す




---

ちょっとした注意

現状、rag-search.sh の出力キーと exec-llama-json-rag.sh 側の取り込みロジック（.dictionary を参照している部分）には差異があります。

実際に使う際は、どちらかに合わせて調整してください。


コーパス更新時は

既存ファイルの中身を変更した場合 → いったん make-json.py を再実行 → db-build.sh は不整合を検知したら自動でフル再構築します。

ファイル追加のみの場合 → make-json.py → db-build.sh が差分追加モードで高速に追記します。