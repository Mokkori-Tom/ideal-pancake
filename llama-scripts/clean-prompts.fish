function clean-prompts
    # 第1引数: 入力ディレクトリ (省略時はカレント)
    if test (count $argv) -ge 1
        set indir (realpath $argv[1])
    else
        set indir (realpath .)
    end

    # 第2引数: 出力ディレクトリ (省略時は ./clean-prompts-out)
    set outdir "./clean-prompts-out"
    if test (count $argv) -ge 2
        set outdir $argv[2]
    end

    # 出力ディレクトリ作成
    mkdir -p "$outdir"

    # 再帰的にファイル処理（ディレクトリ構造を保持）
    find "$indir" -type f | while read -l f
        # indir/ 以降の相対パスを取り出し
        set rel (string replace -r "^$indir/" "" -- "$f")
        set out "$outdir/$rel"

        # 必要なディレクトリを作成
        mkdir -p (dirname "$out")

        # タグ削除処理
        perl -0pe '
            # 1. </sys-prompt> まで削除
            s/\A.*?<\/sys-prompt>//s;

            # 2. </main-prompt> まで削除
            s/\A.*?<\/main-prompt>//s;

            # 3. <think>〜</think> ブロック削除
            s/<think>.*?<\/think>//sg;

            # 4. <file-text>〜</file-text> ブロック削除
            s/<file-text>.*?<\/file-text>//sg;
        ' "$f" > "$out"
    end
end