# 検索対象ディレクトリを指定（引数でもOK）
set dir (realpath (or $argv[1] .))

# <none> を1回だけ含むファイルを検索
rg --count-matches "<none>" -g "*" $dir | awk -F: '$2 == 1 {print $1}'

#./one-none.sh ./data