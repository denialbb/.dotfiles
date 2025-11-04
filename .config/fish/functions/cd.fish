function cd
    if test (count $argv) -eq 0
        builtin cd ~
        return
    else if test -d "$argv[1]"
        builtin cd $argv
    else
        z $argv && printf "\U000F17A9 " && pwd || echo "Error: Directory not found"
    end
end
