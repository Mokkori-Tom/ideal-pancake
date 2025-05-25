import sys
import random

AIZUCHI_LIST = [
    "(っ´ω`c)",
    "( ˘ω˘ )",
    "(・∀・)b",
    "( ﾟｰﾟ)/ﾟ*ﾞ:¨*;.･’☆",
    "(*ﾟ▽ﾟ)ﾉ",
    "( ＾∀＾)",
    "( •ᴗ• )",
    "( ˙꒳​˙ )ｳﾝ",
    "(｡･ω･｡)ﾉ♡",
    "( ｰ̀ωｰ́ )ゞ",
    "(・_・)b",
    "(´∀｀*)ｳﾌﾌ",
    "(ﾟ∀ﾟ)",
    "（っ’ヮ’c）",
    "(*･ω･)ﾉ",
    "(´ー｀)",
    "(´ω｀*)"
]

def parse_pipe_tree(text):
    lines = text.strip().splitlines()
    stack = []
    root = []
    for line in lines:
        depth = line.count('|')
        node_val = line.strip('|').strip()
        if not node_val:
            continue
        elem = [node_val, []]
        if depth == 1:
            root.append(elem)
            stack = [elem]
        else:
            parent = stack[depth - 2]
            parent[1].append(elem)
            if len(stack) < depth:
                stack.append(elem)
            else:
                stack[depth - 1] = elem
    return root

def find_node(nodes, target):
    for node in nodes:
        if node[0] == target:
            return node
    return None

def insert_path_always(tree, path):
    if not path:
        return
    head, *tail = path
    for node in tree:
        if node[0] == head:
            insert_path_always(node[1], tail)
            return
    new_node = [head, []]
    tree.append(new_node)
    insert_path_always(new_node[1], tail)

def find_path_exists(tree, path):
    if not path:
        return False
    head, *tail = path
    for node in tree:
        if node[0] == head:
            if tail:
                return find_path_exists(node[1], tail)
            else:
                return True
    return False

def tree_to_lines(tree, depth=1):
    lines = []
    for node in tree:
        lines.append('|' * depth + node[0])
        lines += tree_to_lines(node[1], depth + 1)
    return lines

def flatten_words(tree, words=None):
    if words is None:
        words = set()
    for node in tree:
        words.add(node[0])
        flatten_words(node[1], words)
    return words

def split_with_known_words(input_text, known_words):
    result = []
    i = 0
    N = len(input_text)
    while i < N:
        match = ""
        for j in range(N, i, -1):
            candidate = input_text[i:j]
            if candidate in known_words:
                match = candidate
                break
        if match:
            result.append(match)
            i += len(match)
        else:
            start = i
            while i < N:
                found = False
                for j in range(N, i, -1):
                    if input_text[i:j] in known_words:
                        found = True
                        break
                if found:
                    break
                i += 1
            result.append(input_text[start:i])
    return result

def follow_path_from_root(tree, path):
    nodes = tree
    for key in path:
        node = find_node(nodes, key)
        if node is None:
            return None
        nodes = node[1]
    return node

def contains_deep(node, target):
    for child in node[1]:
        if child[0] == target:
            return True
        if contains_deep(child, target):
            return True
    return False

def appears_as_parent_child(tree, parent, child):
    def walk(nodes):
        for node in nodes:
            if node[0] == child and contains_deep(node, parent):
                return True
            if node[0] == parent and contains_deep(node, child):
                return True
            if walk(node[1]):
                return True
        return False
    return walk(tree)

def gachi_predict(tree, path):
    node = follow_path_from_root(tree, path)
    if not node:
        return None
    if len(node[1]) == 0:
        return random.choice(AIZUCHI_LIST)
    # ---組み合わせ参照型---
    children = node[1]
    preferred = []
    for child in children:
        if combination_exists_elsewhere(tree, path, child[0]):
            preferred.append(child[0])
    if preferred:
        next_choice = random.choice(preferred)
    else:
        next_choice = random.choice([child[0] for child in children])
    # 続きを補完（さらに分岐がある場合はランダムにたどる）
    result = [next_choice]
    cur = find_node(children, next_choice)
    while cur and len(cur[1]) > 0:
        cur = random.choice(cur[1])
        result.append(cur[0])
    return "".join(result) if result else random.choice(AIZUCHI_LIST)

def combination_exists_elsewhere(tree, path, next_word):
    """tree全体からpath+[next_word]パスが他にあればTrue（現ノード以外で）"""
    def walk(nodes, current_path):
        for node in nodes:
            new_path = current_path + [node[0]]
            # 他の場所で「path+next_word」が現れたらTrue
            if len(new_path) == len(path) + 1 and new_path[:-1] == path and node[0] == next_word:
                return True
            if walk(node[1], new_path):
                return True
        return False
    return walk(tree, [])
    
def reparse_old_nodes(tree, known_words):
    changed = False
    i = 0
    while i < len(tree):
        node = tree[i]
        val = node[0]
        if len(node[1]) == 0:
            split = split_with_known_words(val, known_words)
            if len(split) > 1 and all(w in known_words for w in split):
                del tree[i]
                insert_path_always(tree, split)
                changed = True
                continue
        else:
            changed = reparse_old_nodes(node[1], known_words) or changed
        i += 1
    return changed

def main():
    if len(sys.argv) < 3:
        print("usage: python gachi_emo_combo.py context.txt 'ジャムパンも美味しいです。'")
        print("   or: python gachi_emo_combo.py context.txt パン は")
        sys.exit(1)
    filename = sys.argv[1]
    if len(sys.argv) == 3:
        input_text = sys.argv[2]
    else:
        input_text = "".join(sys.argv[2:])

    with open(filename, encoding='utf-8') as f:
        text = f.read()
    tree = parse_pipe_tree(text)
    known_words = flatten_words(tree)
    tokens = split_with_known_words(input_text, known_words)
    tokens = [w for w in tokens if w]
    unknown = [w for w in tokens if w not in known_words]

    if unknown:
        for w in unknown:
            print(f"[{w}]とは？")
        if not find_path_exists(tree, tokens):
            insert_path_always(tree, tokens)
            known_words = flatten_words(tree)
            while reparse_old_nodes(tree, known_words):
                known_words = flatten_words(tree)
            with open(filename, "w", encoding="utf-8") as f:
                f.write("\n".join(tree_to_lines(tree)))
    else:
        result = gachi_predict(tree, tokens)
        if result:
            print(result)

if __name__ == "__main__":
    main()