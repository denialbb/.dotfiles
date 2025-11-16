function gc
    read -P (set_color yellow)"Commit message: "(set_color normal) msg
    if test -n "$msg"
        git commit -m msg
    end
end

function gpa
    read -P (set_color yellow)"Commit message: "(set_color normal) msg
    if test -n "$msg"
        git add .
        git commit -m msg
        git push
    end
end
