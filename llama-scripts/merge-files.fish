function merge-files
    # 第1引数: 入力ディレクトリ（省略時はカレント）
    set indir (realpath (or $argv[1] .))
    # 第2引数: 出力ファイル（省略時は merged.txt）
    set outfile (or $argv[2] "merged.txt")

    # 出力ファイル初期化
    echo -n "" > "$outfile"

    # ファイル名順に処理
    for f in (find "$indir" -maxdepth 1 -type f | sort)
        echo "***" >> "$outfile"
        cat "$f" >> "$outfile"
        echo "" >> "$outfile"
    end

    echo "Merged (sorted) into $outfile"
end