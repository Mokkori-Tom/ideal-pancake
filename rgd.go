// rgd.go

package main

import (
	"flag"
	"fmt"
	"os"
	"os/exec"
	"strconv"
)

const helpText = `
USAGE:
    rgd [options] <PATTERN> <FILE>

OPTIONS:
    -c, --context N     上下の文脈行数（デフォルト: 5）

DETAIL:
    ripgrep (rg) で <PATTERN> を <FILE> から全文検索し、
    --json 出力を delta でカラー表示します。
    「git管理外ファイル」や巨大ファイルもOK！

EXAMPLE:
    rgd "main" foo.go
    rgd -c 10 TODO memo.txt

備考:
    - rg, delta コマンド必須（PATH通すこと）
    - オプションはどこでもOK（例: rgdelta --context=3 pattern file）

補足:
    カラーと文脈で差分の海を優雅に泳ぎましょう…

`

func main() {
	flag.Usage = func() {
		fmt.Fprint(os.Stderr, helpText)
		flag.PrintDefaults()
	}
	var context int
	flag.IntVar(&context, "c", 5, "上下の文脈行数（デフォルト: 5）")
	flag.IntVar(&context, "context", 5, "上下の文脈行数（長名も可）")
	flag.Parse()
	args := flag.Args()

	if len(args) < 2 {
		flag.Usage()
		os.Exit(1)
	}
	pattern := args[0]
	file := args[1]
	ctxStr := strconv.Itoa(context)

	cmd1 := exec.Command("rg", "--json", "-C", ctxStr, pattern, file)
	cmd2 := exec.Command("delta")

	pipe, err := cmd1.StdoutPipe()
	if err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(2)
	}
	cmd2.Stdin = pipe
	cmd2.Stdout = os.Stdout
	cmd2.Stderr = os.Stderr

	if err := cmd1.Start(); err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(3)
	}
	if err := cmd2.Start(); err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(4)
	}
	cmd1.Wait()
	cmd2.Wait()
}
