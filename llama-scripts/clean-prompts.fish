function clean-prompts
    # 使い方:
    # clean-prompts [入力ディレクトリ] [出力ディレクトリ]
    # 例: clean-prompts ./in ./out

    set indir (realpath (or $argv[1] ./in))
    set outdir (realpath (or $argv[2] ./out))

    mkdir -p $outdir

    # 再帰的にファイルを処理
    for f in (find $indir -type f)
        set rel (string replace -r "^$indir/" "" $f)
        set out "$outdir/$rel"
        mkdir -p (dirname $out)

        # 変換処理: タグ削除
        perl -0pe '
            s/\A.*?<\/sys-prompt>//s;
            s/\A.*?<\/main-prompt>//s;
            s/<think>.*?<\/think>//sg;
        ' $f > $out
    end
end