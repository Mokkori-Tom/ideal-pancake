// colordiff.go
package main

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"os/exec"
)

const helpText = `
USAGE:
    colordiff <file/dir A> <file/dir B>
    colordiff - <file/dir>   # 標準入力との比較
    colordiff <file/dir> -   # 標準入力との比較

DETAIL:
    diff -urN で2つのファイル/ディレクトリを比較し、
    delta でカラー表示します。
    差分がなければ "🎉 差分なし（No differences found）" と表示。

EXAMPLE:
    colordiff foo.txt bar.txt
    cat data.txt | colordiff - ref.txt

備考:
    - diff, delta コマンド必須（PATHに通して）
    - -h または --help でこのヘルプ表示
`

func usage() {
	fmt.Fprint(os.Stderr, helpText)
	os.Exit(1)
}

func runDiff(a, b string) ([]byte, error) {
	var cmd *exec.Cmd
	if a == "-" || b == "-" {
		// 標準入力サポート
		in := os.Stdin
		f := b
		if a != "-" {
			f = a
		}
		cmd = exec.Command("diff", "-u", "--label", "A", "--label", "B", "-", f)
		cmd.Stdin = in
	} else {
		cmd = exec.Command("diff", "-urN", a, b)
	}
	var out bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = os.Stderr
	err := cmd.Run()
	return out.Bytes(), err
}

func pipeDelta(diffout []byte) error {
	delta := exec.Command("delta")
	delta.Stdin = bytes.NewReader(diffout)
	delta.Stdout = os.Stdout
	delta.Stderr = os.Stderr
	return delta.Run()
}

func main() {
	// ヘルプ判定（-h/--help）
	if len(os.Args) == 2 && (os.Args[1] == "-h" || os.Args[1] == "--help") {
		usage()
	}
	if len(os.Args) != 3 {
		usage()
	}
	a, b := os.Args[1], os.Args[2]

	diffout, _ := runDiff(a, b)
	if len(diffout) == 0 {
		fmt.Println("🎉 差分なし（No differences found）")
		os.Exit(0)
	}
	err := pipeDelta(diffout)
	if err != nil && err != io.EOF {
		fmt.Fprintf(os.Stderr, "delta error: %v\n", err)
		os.Exit(1)
	}
}
