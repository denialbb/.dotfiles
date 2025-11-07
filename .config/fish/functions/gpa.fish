function gpa
    read -P (set_color red)"Commit message: "(set_color normal) msg
    if test -n "$msg"
        git add .
        git commit -m "$msg"
        git push
    end
end
