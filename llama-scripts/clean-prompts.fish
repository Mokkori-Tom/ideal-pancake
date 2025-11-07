function clean-prompts
    # 使い方:
    # clean-prompts [入力ディレクトリ] [出力ディレクトリ]
    # 例: clean-prompts ./in ./out

    set indir (or $argv[1] ./in)
    set outdir (or $argv[2] ./out)

    mkdir -p $outdir

    # ファイルを再帰的に処理
    for f in (find $indir -type f)
        set rel (string replace -r "^$indir/" "" $f)
        set out "$outdir/$rel"
        mkdir -p (dirname $out)

        # タグ除去処理
        perl -0pe '
            s/\A.*?<\/sys-prompt>//s;
            s/\A.*?<\/main-prompt>//s;
            s/<think>.*?<\/think>//sg;
        ' $f > $out
    end
end