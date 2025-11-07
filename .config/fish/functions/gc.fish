function gc
    read -P (set_color blue)"Commit message: "(set_color normal) msg
    if test -n "$msg"
        git commit -m "$msg"
    end
end
