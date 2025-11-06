function one-none
    set dir (realpath (or $argv[1] .))
    rg --count-matches "<none>" -g "*" $dir | awk -F: '$2 == 1 {print $1}'
end