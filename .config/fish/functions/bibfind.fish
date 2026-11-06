function _bibfind_root --description "Resolve the biblios repository root (env > git > bibtrack dir > default)"
    if set -q BIBLIOS_ROOT; and test -n "$BIBLIOS_ROOT"
        echo "$BIBLIOS_ROOT"
        return 0
    end

    set -l git_root (git rev-parse --show-toplevel 2>/dev/null)
    if test -n "$git_root"; and test -f "$git_root/DB DUMP/InventarioLibri.csv"
        echo "$git_root"
        return 0
    end

    set -l bt (command -v bibtrack 2>/dev/null)
    if test -n "$bt"
        set -l bt_real (realpath "$bt" 2>/dev/null)
        if test -n "$bt_real"
            dirname "$bt_real"
            return 0
        end
    end

    echo "/home/denial/Work/biblios"
end


function _bibfind_wrap --description "Char-aware word wrap (string length, not byte fold)"
    set -l text (string trim -- $argv[1])
    set -l width $argv[2]

    if test -z "$text"
        return
    end

    set -l words (string match -r -a '[^[:space:]]+' -- "$text")
    set -l lines
    set -l cur ""
    set -l cur_len 0

    for w in $words
        set -l wlen (string length -- "$w")

        if test $wlen -gt $width
            if test -n "$cur"
                set -a lines "$cur"
                set cur ""
                set cur_len 0
            end
            set -l pos 1
            while test $pos -le $wlen
                set -a lines (string sub -s $pos -l $width -- "$w")
                set pos (math $pos + $width)
            end
            continue
        end

        set -l add $wlen
        if test -n "$cur"
            set add (math $add + 1)
        end

        if test (math $cur_len + $add) -le $width
            if test -n "$cur"
                set cur "$cur $w"
            else
                set cur "$w"
            end
            set cur_len (math $cur_len + $add)
        else
            set -a lines "$cur"
            set cur "$w"
            set cur_len $wlen
        end
    end

    if test -n "$cur"
        set -a lines "$cur"
    end

    for l in $lines
        echo "$l"
    end
end


function _bibfind_card_row --description "Render one wrapped label/value row of the card"
    set -l label $argv[1]
    set -l color $argv[2]
    set -l raw (string trim -- $argv[3])
    set -l val_w $argv[4]
    set -l border $argv[5]
    set -l reset $argv[6]
    set -l dim $argv[7]

    if test -z "$raw"
        set -l pad ""
        if test (math $val_w - 1) -gt 0
            set pad (string repeat -n (math $val_w - 1) " ")
        end
        printf "%s│%s  \033[1m%-11s:\033[0m %s—%s%s%s│%s\n" "$border" "$reset" "$label" "$dim" "$reset" "$pad" "$border" "$reset"
        return
    end

    set -l first 1
    for l in (_bibfind_wrap "$raw" $val_w)
        set -l cur_len (string length -- "$l")
        set -l pad ""
        set -l pad_len (math $val_w - $cur_len)
        if test $pad_len -gt 0
            set pad (string repeat -n $pad_len " ")
        end
        if test $first -eq 1
            printf "%s│%s  \033[1m%-11s:\033[0m %s%s%s%s%s│%s\n" "$border" "$reset" "$label" "$color" "$l" "$reset" "$pad" "$border" "$reset"
            set first 0
        else
            printf "%s│%s               %s%s%s%s%s│%s\n" "$border" "$reset" "$color" "$l" "$reset" "$pad" "$border" "$reset"
        end
    end
end


function _bibfind_print_card --description "Pretty print book details card (status-dependent border & badge)"
    set -l title $argv[1]
    set -l author $argv[2]
    set -l inv $argv[3]
    set -l dewey $argv[4]
    set -l pub $argv[5]
    set -l subj $argv[6]
    set -l price $argv[7]
    set -l loc $argv[8]
    set -l notes (string replace -r "<[^>]+>" "" -- "$argv[9]")

    # Card width: default 72, use FZF_PREVIEW_COLUMNS when available
    set -l card_w 72
    if set -q FZF_PREVIEW_COLUMNS; and string match -qr '^[0-9]+$' -- "$FZF_PREVIEW_COLUMNS"; and test $FZF_PREVIEW_COLUMNS -ge 24
        set card_w $FZF_PREVIEW_COLUMNS
    end

    # Status-dependent border & badge
    set -l border (printf '\e[38;5;39m')
    set -l badge ""
    if string match -qi "*ESTINTO*" -- "$notes"
        set border (printf '\e[38;5;196m')
        set badge "[ESTINTO]"
    else if string match -qi "*MAGAZZINO*" -- "$notes"
        set border (printf '\e[38;5;214m')
        set badge "[IN MAGAZZINO]"
    end

    # Tracker badge precedence: open (DUPLICATO) first, then resolved (RISOLTO)
    set -l cache_open "$HOME/.cache/biblios/tracker_open_invs.txt"
    set -l cache_resolved "$HOME/.cache/biblios/tracker_resolved_invs.txt"
    if test -f "$cache_open"; and grep -Fxq "$inv" "$cache_open" 2>/dev/null
        if test -n "$badge"
            set badge "$badge [DUPLICATO]"
        else
            set badge "[DUPLICATO]"
            set border (printf '\e[38;5;208m')
        end
    else if test -f "$cache_resolved"; and grep -Fxq "$inv" "$cache_resolved" 2>/dev/null
        if test -n "$badge"
            set badge "$badge [RISOLTO]"
        else
            set badge "[RISOLTO]"
            set border (printf '\e[38;5;42m')
        end
    end

    set -l reset (printf '\e[0m')
    set -l dim (printf '\e[0;90m')
    set -l c_title (printf '\e[1;33m')
    set -l c_author (printf '\e[1;32m')
    set -l c_inv (printf '\e[1;36m')
    set -l c_dewey (printf '\e[1;35m')
    set -l c_plain (printf '\e[0;37m')
    set -l c_note (printf '\e[1;31m')
    set -l val_w (math $card_w - 15)

    if test -n "$badge"
        set -l badge_len (string length -- "$badge")
        set -l rem (math $card_w - 4 - $badge_len)
        set -l dashes ""
        if test $rem -gt 0
            set dashes (string repeat -n $rem "─")
        end
        echo -e "$border╭── \033[1m$badge\033[0m$border $dashes╮$reset"
    else
        echo -e "$border╭"(string repeat -n $card_w "─")"╮$reset"
    end

    _bibfind_card_row "Titolo" $c_title "$title" $val_w "$border" "$reset" "$dim"
    _bibfind_card_row "Autore" $c_author "$author" $val_w "$border" "$reset" "$dim"
    _bibfind_card_row "Inventario" $c_inv "$inv" $val_w "$border" "$reset" "$dim"
    _bibfind_card_row "Dewey" $c_dewey "$dewey" $val_w "$border" "$reset" "$dim"
    _bibfind_card_row "Editore" $c_plain "$pub" $val_w "$border" "$reset" "$dim"
    _bibfind_card_row "Soggetto" $c_plain "$subj" $val_w "$border" "$reset" "$dim"
    _bibfind_card_row "Prezzo" $c_plain "$price" $val_w "$border" "$reset" "$dim"
    _bibfind_card_row "Ubicazione" $c_plain "$loc" $val_w "$border" "$reset" "$dim"
    _bibfind_card_row "Note" $c_note "$notes" $val_w "$border" "$reset" "$dim"

    echo -e "$border╰"(string repeat -n $card_w "─")"╯$reset"
end


function _bibfind_print_rows --description "Print output for one or more selected TSV rows (mode: id|raw|cards)"
    set -l mode cards
    if test (count $argv) -gt 0
        set mode $argv[1]
    end
    set -l rows $argv[2..-1]

    set -l first 1
    for row in $rows
        set -l fields (string split \t -- "$row")
        switch $mode
            case id
                echo "$fields[3]"
            case raw
                echo "$row"
            case '*'
                if test $first -eq 0
                    echo
                end
                _bibfind_print_card $fields
                set first 0
        end
    end
end


function bibfind --description "Fuzzy find books in library DB dump (floating tmux popup & clean card)"
    argparse 't/title' 'a/author' 'i/inv' 'd/dewey' 'e/estinti' '1/id' 'r/raw' 'R/resolve=' 'h/help' 'card' -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: bibfind [options] [query]"
        echo ""
        echo "Options:"
        echo "  -t, --title    Lookup by title (default)"
        echo "  -a, --author   Combined author + title lookup"
        echo "  -i, --inv      Lookup by inventory number"
        echo "  -d, --dewey    Lookup by Dewey classification / call number"
        echo "  -e, --estinti  Lookup in weeded / discarded catalog (estinti)"
        echo "  -R, --resolve  Mark inventory duplicate anomaly as resolved in tracker"
        echo "  -1, --id       Output only inventory ID on accept"
        echo "  -r, --raw      Output raw tab-separated record"
        echo "  -h, --help     Show this help message"
        echo ""
        echo "TUI keys (fzf):"
        echo "  Tab     Mark/unmark a record for multi-selection"
        echo "  Enter   Print selected card(s) (all marked records if any)"
        echo "  Ctrl-E  Toggle current/estinti catalog"
        echo "  Ctrl-R  Resolve highlighted inventory (tracker)"
        echo "  Ctrl-T  Search by title"
        echo "  Ctrl-A  Search by author + title"
        echo "  Alt-I   Search by inventory number"
        echo "  Ctrl-D  Search by Dewey / call number"
        echo "  Ctrl-Y  Copy inventory ID to clipboard"
        echo "  Ctrl-/  Toggle preview pane"
        return 0
    end

    set -l root (_bibfind_root)
    set -l bibtrack_bin "$root/bibtrack"
    if not test -x "$bibtrack_bin"
        set bibtrack_bin (command -v bibtrack 2>/dev/null)
    end

    if set -q _flag_resolve
        if test -n "$bibtrack_bin"
            $bibtrack_bin resolve "$_flag_resolve"
            return $status
        else
            echo "bibfind: 'bibtrack' non trovato" >&2
            return 1
        end
    end

    if set -q _flag_card
        _bibfind_print_card $argv
        return 0
    end

    # 1. Resolve CSV location
    set -l csv_path "$root/DB DUMP/InventarioLibri.csv"
    if not test -f "$csv_path"
        echo "bibfind: 'DB DUMP/InventarioLibri.csv' non trovato (root: $root)" >&2
        return 1
    end

    # 2. Cache clean TSVs: Col 1 = Titolo, Col 2 = Autore, Col 3 = Inventario, Col 4 = Dewey
    set -l cache_dir "$HOME/.cache/biblios"
    set -l cache_all "$cache_dir/inventario.tsv"
    set -l cache_current "$cache_dir/inventario_current.tsv"
    set -l cache_estinti "$cache_dir/inventario_estinti.tsv"
    set -l toggle_script "$cache_dir/toggle.sh"
    set -l script_path (status filename)
    set -l cache_version "2"
    set -l cache_stamp "$cache_dir/.bibfind_version"

    set -l need_rebuild 0
    if not test -f "$cache_current"; or not test -f "$cache_estinti"; or not test -f "$cache_all"
        set need_rebuild 1
    else if test "$csv_path" -nt "$cache_current"
        set need_rebuild 1
    else if test "$script_path" -nt "$cache_current"
        set need_rebuild 1
    else if test "$cache_version" != (cat "$cache_stamp" 2>/dev/null)
        set need_rebuild 1
    end

    if test "$need_rebuild" = 1
        mkdir -p "$cache_dir"
        python3 -c "
import html, re, sys
src, dst_all, dst_cur, dst_est = sys.argv[1:5]
with open(src, 'r', encoding='utf-8', errors='replace') as f, \
     open(dst_all, 'w', encoding='utf-8') as f_all, \
     open(dst_cur, 'w', encoding='utf-8') as f_cur, \
     open(dst_est, 'w', encoding='utf-8') as f_est:
    for _ in range(4): next(f)
    for line in f:
        clean = html.unescape(line.rstrip('\r\n'))
        parts = [p.strip() for p in clean.split(';')]
        if len(parts) > 9 and parts[-1] == '':
            parts = parts[:-1]
        if len(parts) > 9:
            excess = len(parts) - 9
            merged = '; '.join(parts[2 : 2 + excess + 1])
            parts = parts[:2] + [merged] + parts[2 + excess + 1:]
        while len(parts) < 9:
            parts.append('')
        note = re.sub(r'<[^>]+>', '', parts[8]).strip()
        row_str = '\t'.join([parts[2], parts[3], parts[1], parts[0], parts[4], parts[5], parts[6], parts[7], note]) + '\n'
        f_all.write(row_str)
        if 'ESTINTO' in note.upper():
            f_est.write(row_str)
        else:
            f_cur.write(row_str)
" "$csv_path" "$cache_all" "$cache_current" "$cache_estinti"
        printf '%s\n' "$cache_version" > "$cache_stamp"
    end

    set -l toggle_content '#!/bin/sh
state_file="$1"
cache_cur="$2"
cache_est="$3"
if [ "$(cat "$state_file" 2>/dev/null)" = "current" ]; then
    echo "estinti" > "$state_file"
    echo "reload(cat \"$cache_est\")+change-border-label( Biblios Catalog [ESTINTI] )"
else
    echo "current" > "$state_file"
    echo "reload(cat \"$cache_cur\")+change-border-label( Biblios Catalog [CURRENT] )"
fi'
    set -l existing_toggle (string collect < "$toggle_script" 2>/dev/null)
    if not test -f "$toggle_script"; or test "$existing_toggle" != "$toggle_content"
        printf '%s\n' "$toggle_content" > "$toggle_script"
        chmod +x "$toggle_script"
    end

    # 3. Determine search dataset & mode
    set -l search_file "$cache_current"
    set -l mode "current"
    set -l border_label " Biblios Catalog [CURRENT] "
    if set -q _flag_estinti
        set search_file "$cache_estinti"
        set mode "estinti"
        set border_label " Biblios Catalog [ESTINTI] "
    end

    # 4. Determine search scope & prompt (no emojis)
    set -l nth 1
    set -l prompt "Titolo > "
    if set -q _flag_inv
        set nth 3
        set prompt "Inventario > "
    else if set -q _flag_dewey
        set nth 4
        set prompt "Dewey > "
    else if set -q _flag_author
        set nth 1,2
        set prompt "Autore+Titolo > "
    end

    # 5. Preview card via hidden --card flag (same card as Enter, with badges)
    set -l preview_cmd "fish -c 'bibfind --card \$argv' -- {1} {2} {3} {4} {5} {6} {7} {8} {9}"

    # 6. Core fzf options
    set -l state_file "/tmp/bibfind_state.$fish_pid"
    echo "$mode" > "$state_file"

    set -l header_str "[C-E] Estinti/Cur | [C-R] Risolvi | [C-T] Titolo | [C-A] Aut | [A-I] Inv | [C-D] Dewey | [C-Y] Copy ID | [C-/] Preview"

    set -l bibtrack_q (string replace -a "'" "'\\''" -- "$bibtrack_bin")
    set bibtrack_q "'$bibtrack_q'"

    set -l fzf_opts \
        --layout=reverse \
        --border=rounded \
        --border-label="$border_label" \
        --border-label-pos=2 \
        --prompt="$prompt" \
        --delimiter=\t \
        --nth="$nth" \
        --with-nth=1,2,3,4 \
        --multi \
        --ignore-case \
        --tiebreak=begin,length \
        --preview="$preview_cmd" \
        --preview-window="right,50%,border-rounded" \
        --preview-label=" Record Card " \
        --header="$header_str" \
        --bind="ctrl-t:change-prompt(Titolo > )+change-nth(1)" \
        --bind="ctrl-a:change-prompt(Autore+Titolo > )+change-nth(1,2)" \
        --bind="alt-i:change-prompt(Inventario > )+change-nth(3)" \
        --bind="ctrl-d:change-prompt(Dewey > )+change-nth(4)" \
        --bind="ctrl-e:transform:$toggle_script '$state_file' '$cache_current' '$cache_estinti'" \
        --bind="ctrl-y:execute-silent(echo -n {3} | wl-copy 2>/dev/null || echo -n {3} | xclip -sel clip 2>/dev/null)" \
        --bind="ctrl-/:toggle-preview"

    if test -n "$bibtrack_bin"
        set -a fzf_opts --bind="ctrl-r:transform:$bibtrack_q resolve-transform {3}"
    end

    # 7. Inline query: exact/fuzzy resolution
    set -l selected
    if test (count $argv) -gt 0
        set -l query (string join ' ' -- $argv)

        set -l matches
        if set -q _flag_inv
            # exact field-3 equality first (awk), then fuzzy fallback (--exact)
            set matches (awk -F'\t' -v q="$query" '$3 == q' "$search_file")
            if test (count $matches) -eq 0
                set matches (cat "$search_file" | fzf --filter="$query" --delimiter=\t --with-nth=1,2,3,4 --nth=3 --ignore-case --exact)
            end
        else
            set matches (cat "$search_file" | fzf --filter="$query" --delimiter=\t --with-nth=1,2,3,4 --nth="$nth" --ignore-case)
        end

        if test (count $matches) -eq 0
            rm -f "$state_file"
            set -l est_check
            if not set -q _flag_estinti
                if set -q _flag_inv
                    set est_check (cat "$cache_estinti" | fzf --filter="$query" --delimiter=\t --with-nth=1,2,3,4 --nth=3 --ignore-case --exact)
                else
                    set est_check (cat "$cache_estinti" | fzf --filter="$query" --delimiter=\t --with-nth=1,2,3,4 --nth="$nth" --ignore-case)
                end
            end
            if test (count $est_check) -gt 0
                echo "bibfind: nessun risultato per '$query' (presente tra gli estinti: usa -e)" >&2
            else
                echo "bibfind: nessun risultato per '$query'" >&2
            end
            return 1
        else if test (count $matches) -eq 1
            set selected $matches[1]
        else if set -q _flag_dewey; and test (count $matches) -gt 1
            # in dewey mode, prefer an exact call-number match among fuzzy hits
            set -l exact_matches
            for m in $matches
                set -l f (string split \t -- "$m")
                if test (string lower -- "$f[4]") = (string lower -- "$query")
                    set -a exact_matches $m
                end
            end
            if test (count $exact_matches) -eq 1
                set selected $exact_matches[1]
            end
        end
    end

    # 8. Launch fzf if not resolved to a single hit
    if test (count $selected) -eq 0
        if test (count $argv) -gt 0
            set -a fzf_opts --query=(string join ' ' -- $argv)
        end

        set -l fzf_launch
        if test -n "$TMUX"
            set -a fzf_launch --tmux=center,85%,80%
        else
            set -a fzf_launch --height=85%
        end

        set selected (cat "$search_file" | fzf $fzf_launch $fzf_opts)
        rm -f "$state_file"

        if test (count $selected) -eq 0
            return 1
        end
    else
        rm -f "$state_file"
    end

    # 9. Handle output / pretty print (one line per selected/marked record)
    set -l mode cards
    if set -q _flag_id
        set mode id
    else if set -q _flag_raw
        set mode raw
    end

    _bibfind_print_rows $mode $selected
end
