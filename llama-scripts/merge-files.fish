function merge-files
    # 第1引数: 結合元ディレクトリ (省略時はカレント)
    if test (count $argv) -ge 1
        set src (realpath $argv[1])
    else
        set src (realpath .)
    end

    # 第2引数: 出力ファイルパス (省略時は ./merged.txt)
    set outfile "./merged.txt"
    if test (count $argv) -ge 2
        set outfile $argv[2]
    end

    # 出力先ディレクトリを作成
    set outdir (dirname "$outfile")
    mkdir -p "$outdir"

    # 出力ファイルを空で作成
    echo -n "" > "$outfile"

    # 出力ファイルの絶対パスを取得
    set outfile_abs (realpath "$outfile")

    # src 直下のファイルを名前順ソートで結合
    for f in (find "$src" -maxdepth 1 -type f | sort)
        # 出力ファイル自身はスキップ
        if test "$f" = "$outfile_abs"
            continue
        end

        echo "***" >> "$outfile"
        cat "$f" >> "$outfile"
        echo "" >> "$outfile"
    end

    echo "Merged (sorted) into $outfile"
end