#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os, sys, json

INTERVAL   = int(os.getenv("INTERVAL", "3000"))
OVERLAP    = INTERVAL // 2              # 常に50%
GROUP_SIZE = int(os.getenv("GROUP_SIZE", "1"))  # 1行に束ねるチャンク数（>=1）

def main():
    if INTERVAL <= 1 or GROUP_SIZE <= 0:
        print("INTERVAL>1 かつ GROUP_SIZE>=1 にしてね", file=sys.stderr)
        return 2

    text = sys.stdin.read()
    n = len(text)
    if n == 0:
        return 0

    step = INTERVAL - OVERLAP  # = INTERVAL//2
    # 全チャンク作成
    chunks = []
    for i, s in enumerate(range(0, n, step)):
        e = min(s + INTERVAL, n)
        chunks.append({"index": i, "segment": text[s:e]})

    if GROUP_SIZE == 1:
        # 単チャンク出力（従来）
        for ch in chunks:
            print(json.dumps(ch, ensure_ascii=False))
        return 0

    # GROUP_SIZE > 1: スライディングウィンドウ（重なるグループ）
    m = len(chunks)
    if m == 0:
        return 0

    g = 0
    if m <= GROUP_SIZE:
        # 足りないときは1グループだけ（ある分すべて）
        print(json.dumps({"group_index": g, "segments": chunks}, ensure_ascii=False))
    else:
        # [0..k-1], [1..k], [2..k+1], ...
        for start in range(0, m - GROUP_SIZE + 1):
            group = chunks[start:start + GROUP_SIZE]
            print(json.dumps({"group_index": g, "segments": group}, ensure_ascii=False))
            g += 1
    return 0

if __name__ == "__main__":
    sys.exit(main())

