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

    # 出力ファイルを初期化して、ここで作成しておく
    echo -n "" > "$outfile"
    set outfile_abs (realpath "$outfile")

    # ファイル名でソートして結合（サブディレクトリは無視）
    for f in (find "$src" -maxdepth 1 -type f | sort)
        set f_abs (realpath "$f")

        # 出力ファイル自身はスキップ
        if test "$f_abs" = "$outfile_abs"
            continue
        end

        echo "***" >> "$outfile"
        cat "$f" >> "$outfile"
        echo "" >> "$outfile"
    end

    echo "Merged (sorted) into $outfile"
end