import sys
from collections import Counter

NUM_MERGES = 1
MIN_FREQ = 2
MAX_LEN = 8

def load_corpus(path):
    with open(path, encoding="utf-8") as f:
        return [line.strip() for line in f if line.strip()]

def extract_vocab(lines):
    ngram = Counter()
    for line in lines:
        for n in range(2, MAX_LEN+1):
            for i in range(len(line)-n+1):
                ngram[line[i:i+n]] += 1
    vocab = [ng for ng, c in ngram.items() if c >= MIN_FREQ]
    chars = sorted({c for line in lines for c in line})
    vocab = sorted(set(vocab), key=lambda x: -len(x)) + chars
    return vocab

def split(line, vocab):
    vocab_sorted = sorted(set(vocab), key=lambda x: -len(x))
    result, i, buf = [], 0, ""
    while i < len(line):
        for v in vocab_sorted:
            if line.startswith(v, i):
                if buf: result.append(buf); buf = ""
                result.append(v)
                i += len(v)
                break
        else:
            buf += line[i]
            i += 1
    if buf: result.append(buf)
    return result

def bpe_merge(vocab, lines, merges=NUM_MERGES):
    for _ in range(merges):
        tokens = [split(line, vocab) for line in lines]
        pair = Counter()
        for t in tokens:
            for i in range(len(t)-1):
                pair[(t[i], t[i+1])] += 1
        if not pair: break
        (a, b), cnt = pair.most_common(1)[0]
        if cnt < 2: break
        merged = a + b
        if merged not in vocab: vocab.append(merged)
    return vocab

def main():
    if len(sys.argv) < 2:
        print("Usage: python bpe_ngram_vocab.py corpus.txt")
        sys.exit(1)
    lines = load_corpus(sys.argv[1])
    vocab = extract_vocab(lines)
    vocab = bpe_merge(vocab, lines, NUM_MERGES) if NUM_MERGES > 0 else vocab
    print("=== 語彙 ===\n" + "\n".join(vocab))
    print("=== 分割例 ===")
    for line in lines:
        print(f"{line} : {split(line, vocab)}")

if __name__ == "__main__":
    main()