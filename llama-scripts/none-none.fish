function none-none
    # 第1引数: 探索ディレクトリ (省略時はカレント)
    if test (count $argv) -ge 1
        set src (realpath $argv[1])
    else
        set src (realpath .)
    end

    # 第2引数: 保存先ディレクトリ (省略時は ./one-none-out)
    set dst "./one-none-out"
    if test (count $argv) -ge 2
        set dst $argv[2]
    end

    # 保存先ディレクトリを作成
    mkdir -p "$dst"

    # <none> を一度も含まないファイルをコピー
    rg --files-without-match -g "*" "<none>" "$src" \
    | while read -l f
        cp -- "$f" "$dst"/
    end
end