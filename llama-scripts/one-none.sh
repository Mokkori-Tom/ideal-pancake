function none-one
    if test (count $argv) -gt 0
        set dir (realpath $argv[1])
    else
        set dir (realpath .)
    end
    rg --count-matches "<none>" -g "*" $dir | awk -F: '$2 == 1 {print $1}'
end