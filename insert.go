// insert.go

package main

import (
	"bufio"
	"fmt"
	"io"
	"os"
	"strconv"
)

const helpText = `
insert.go - 指定したテキストファイルの指定行に、他のファイル内容を挿入する

Usage:
    go run insert.go <target.txt> <line_no> <insert.txt>

    <target.txt>   挿入先となるテキストファイル
    <line_no>      挿入開始行番号 (1始まり)
    <insert.txt>   挿入するファイル

Notes:
    - <insert.txt> の内容は <target.txt> の <line_no> 行目直前に挿入されます。
    - <line_no> がファイル末尾を超える場合は末尾に挿入されます。
    - 挿入先と挿入元が同じファイルの場合は拒否します（自己挿入禁止）。
    - Windows等でrename失敗時も確実に上書き。
    - 権限等で失敗時はエラー出力。

例:
    go run insert.go memo.txt 10 insert.txt

    一言:  
    自己挿入はご法度ですので…ご容赦を…💦
`

func main() {
	// --- ヘルプ出力対応 ---
	if len(os.Args) == 2 && (os.Args[1] == "-h" || os.Args[1] == "--help") {
		fmt.Print(helpText)
		os.Exit(0)
	}
	if len(os.Args) != 4 {
		fmt.Fprintf(os.Stderr, helpText)
		os.Exit(1)
	}
	if len(os.Args) != 4 {
		fmt.Fprintf(os.Stderr, "Usage: go run insert.go <target.txt> <line_no> <insert.txt>\n")
		os.Exit(1)
	}
	target := os.Args[1]
	lineno, err := strconv.Atoi(os.Args[2])
	if err != nil || lineno < 1 {
		fmt.Fprintln(os.Stderr, "行番号は1以上の整数で")
		os.Exit(1)
	}
	insertFile := os.Args[3]
	if target == insertFile {
		fmt.Fprintln(os.Stderr, "挿入ファイルと編集ファイルが同じです。自己挿入は禁止です！")
		os.Exit(1)
	}

	// 挿入ファイル読み込み
	var insertLines []string
	f, err := os.Open(insertFile)
	if err != nil {
		fmt.Fprintln(os.Stderr, "挿入ファイル開けません:", err)
		os.Exit(1)
	}
	defer f.Close()
	sc := bufio.NewScanner(f)
	for sc.Scan() {
		insertLines = append(insertLines, sc.Text())
	}
	if err := sc.Err(); err != nil {
		fmt.Fprintln(os.Stderr, "挿入ファイル読み込みエラー:", err)
		os.Exit(1)
	}

	// 本体ファイル読み込み
	var lines []string
	in, err := os.Open(target)
	if err != nil {
		fmt.Fprintln(os.Stderr, "本体ファイル開けません:", err)
		os.Exit(1)
	}
	defer in.Close()
	sc2 := bufio.NewScanner(in)
	for sc2.Scan() {
		lines = append(lines, sc2.Text())
	}
	if err := sc2.Err(); err != nil {
		fmt.Fprintln(os.Stderr, "本体ファイル読み込みエラー:", err)
		os.Exit(1)
	}

	// 出力
	tmpfile := target + ".tmp"
	out, err := os.Create(tmpfile)
	if err != nil {
		fmt.Fprintln(os.Stderr, "一時ファイル作成失敗:", err)
		os.Exit(1)
	}
	defer out.Close()
	for i, line := range lines {
		if i+1 == lineno {
			for _, ins := range insertLines {
				fmt.Fprintln(out, ins)
			}
		}
		fmt.Fprintln(out, line)
	}
	if lineno > len(lines) {
		for _, ins := range insertLines {
			fmt.Fprintln(out, ins)
		}
	}
	out.Close()

	// Windowsではrename失敗対策としてcopy+上書き
	err = copyFile(tmpfile, target)
	if err != nil {
		fmt.Fprintln(os.Stderr, "ファイル上書き失敗:", err)
		os.Exit(1)
	}
	os.Remove(tmpfile)
}

func copyFile(src, dst string) error {
	in, err := os.Open(src)
	if err != nil {
		return err
	}
	defer in.Close()
	out, err := os.Create(dst)
	if err != nil {
		return err
	}
	defer out.Close()
	_, err = io.Copy(out, in)
	return err
}
