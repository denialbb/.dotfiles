function set-wallpaper
    if test (count $argv) -eq 0
        killall hyprpaper
        hyprpaper >/dev/null &
    else if test -f "$argv[2]"
        if test $argv[1] = 1
            echo "Changing wallpaper 1"
            rm ~/.wallpaper1.png
            ln -s $argv[2] ~/.wallpaper1.png
        else if test $argv[1] = 2
            echo "Changing wallpaper 2"
            rm ~/.wallpaper2.png
            ln -s $argv[2] ~/.wallpaper2.png
        end

        killall hyprpaper
        hyprpaper >/dev/null &
    end
end
