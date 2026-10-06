function bibfind --description "Fuzzy find books in library DB dump (floating tmux popup & clean card)"
    argparse 't/title' 'a/author' 'i/inv' 'd/dewey' '1/id' 'r/raw' 'h/help' -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: bibfind [options] [query]"
        echo ""
        echo "Options:"
        echo "  -t, --title    Lookup by title (default)"
        echo "  -a, --author   Combined author + title lookup"
        echo "  -i, --inv      Lookup by inventory number"
        echo "  -d, --dewey    Lookup by Dewey classification / call number"
        echo "  -1, --id       Output only inventory ID on accept"
        echo "  -r, --raw      Output raw tab-separated record"
        echo "  -h, --help     Show this help message"
        return 0
    end

    # 1. Resolve CSV location
    set -l csv_path "DB DUMP/InventarioLibri.csv"
    if not test -f "$csv_path"
        set -l git_root (git rev-parse --show-toplevel 2>/dev/null)
        if test -f "$git_root/DB DUMP/InventarioLibri.csv"
            set csv_path "$git_root/DB DUMP/InventarioLibri.csv"
        else if test -f "/home/denial/Work/biblios/DB DUMP/InventarioLibri.csv"
            set csv_path "/home/denial/Work/biblios/DB DUMP/InventarioLibri.csv"
        else
            echo "bibfind: 'DB DUMP/InventarioLibri.csv' not found" >&2
            return 1
        end
    end

    # 2. Cache clean TSV: Col 1 = Titolo, Col 2 = Autore, Col 3 = Inventario, Col 4 = Dewey
    set -l cache_dir "$HOME/.cache/biblios"
    set -l cache_tsv "$cache_dir/inventario.tsv"
    if not test -f "$cache_tsv"; or test "$csv_path" -nt "$cache_tsv"
        mkdir -p "$cache_dir"
        python3 -c "
import html, re, sys
src, dst = sys.argv[1], sys.argv[2]
with open(src, 'r', encoding='utf-8', errors='replace') as f, open(dst, 'w', encoding='utf-8') as out:
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
        # Order: 0:Titolo, 1:Autore, 2:Inventario, 3:Dewey, 4:Editore, 5:Soggetto, 6:Prezzo, 7:Ubicazione, 8:Note
        out_row = [parts[2], parts[3], parts[1], parts[0], parts[4], parts[5], parts[6], parts[7], note]
        out.write('\t'.join(out_row) + '\n')
" "$csv_path" "$cache_tsv"
    end

    # 3. Determine search scope & prompt (no emojis)
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

    # 4. Preview card definition for TUI (auto-wraps inside preview pane)
    set -l preview_cmd 'printf "\
\033[1;33mTitolo     :\033[0m %s\n\
\033[1;32mAutore     :\033[0m %s\n\
\033[1;36mInventario :\033[0m %s\n\
\033[1;35mDewey      :\033[0m %s\n\
\033[1;34mEditore    :\033[0m %s\n\
\033[0;37mSoggetto   :\033[0m %s\n\
\033[0;37mPrezzo     :\033[0m %s\n\
\033[0;37mUbicazione :\033[0m %s\n\
\033[1;31mNote       :\033[0m %s\n" {1} {2} {3} {4} {5} {6} {7} {8} {9}'

    # 5. Core fzf options with live scope switching & word wrapping
    set -l fzf_opts \
        --layout=reverse \
        --border=rounded \
        --border-label=" Biblios Catalog " \
        --border-label-pos=2 \
        --prompt="$prompt" \
        --delimiter=\t \
        --nth="$nth" \
        --with-nth=1,2,3 \
        --ignore-case \
        --tiebreak=begin,length \
        --preview="$preview_cmd" \
        --preview-window="right,50%,border-rounded,wrap-word" \
        --preview-wrap-sign="             " \
        --preview-label=" Record Card " \
        --header="[Enter] View Card | [C-T] Titolo | [C-A] Autore | [C-I] Inv | [C-D] Dewey | [C-Y] Copy ID" \
        --bind="ctrl-t:change-prompt(Titolo > )+change-nth(1)" \
        --bind="ctrl-a:change-prompt(Autore+Titolo > )+change-nth(1,2)" \
        --bind="ctrl-i:change-prompt(Inventario > )+change-nth(3)" \
        --bind="ctrl-d:change-prompt(Dewey > )+change-nth(4)" \
        --bind="ctrl-y:execute-silent(echo -n {3} | wl-copy 2>/dev/null || echo -n {3} | xclip -sel clip 2>/dev/null)" \
        --bind="ctrl-/:toggle-preview"

    # 6. Check inline query: if exactly 1 hit, bypass fzf entirely
    set -l selected
    if test (count $argv) -gt 0
        set -l query (string join ' ' -- $argv)
        set -l matches (cat "$cache_tsv" | fzf --filter="$query" --delimiter=\t --nth="$nth" --ignore-case)
        if test (count $matches) -eq 1
            set selected $matches[1]
        else if set -q _flag_inv; and test (count $matches) -gt 1
            # In inventory mode, check if there is an exact ID match
            set -l exact_matches
            for m in $matches
                set -l f (string split \t -- "$m")
                if test "$f[3]" = "$query"
                    set -a exact_matches $m
                end
            end
            if test (count $exact_matches) -eq 1
                set selected $exact_matches[1]
            end
        else if set -q _flag_dewey; and test (count $matches) -gt 1
            # In dewey mode, check if there is an exact call number match
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

    # 7. If not resolved to a single hit, launch fzf (tmux popup if in tmux)
    if test -z "$selected"
        if test (count $argv) -gt 0
            set -a fzf_opts --query=(string join ' ' -- $argv)
        end

        if test -n "$TMUX"; or tmux display-message -p '#{session_name}' >/dev/null 2>&1
            set selected (cat "$cache_tsv" | fzf-tmux -p 85%,80% -- $fzf_opts)
        else
            set selected (cat "$cache_tsv" | fzf --height=85% $fzf_opts)
        end

        if test -z "$selected"
            return 1
        end
    end

    # 8. Handle output / pretty print
    set -l fields (string split \t -- "$selected")

    if set -q _flag_id
        echo "$fields[3]"
        return 0
    end

    if set -q _flag_raw
        echo "$selected"
        return 0
    end

    # Pretty print card on Enter
    _bibfind_print_card $fields
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

    # Status-dependent border & badge
    set -l border "\033[38;5;39m" # Sky blue (active catalog item)
    set -l badge ""
    if string match -qi "*ESTINTO*" -- "$notes"
        set border "\033[38;5;196m" # Red (weeded / discarded)
        set badge "[ESTINTO]"
    else if string match -qi "*MAGAZZINO*" -- "$notes"
        set border "\033[38;5;214m" # Amber (storage / archive)
        set badge "[IN MAGAZZINO]"
    end

    set -l reset "\033[0m"
    set -l dim "\033[0;90m"
    set -l inner_w 72
    set -l val_w 57 # 72 - 15 prefix width

    # Top border with optional badge
    if test -n "$badge"
        set -l badge_len (string length -- "$badge")
        set -l rem_dashes (math $inner_w - 4 - $badge_len)
        echo -e "$border╭── \033[1m$badge\033[0m$border "(string repeat -n $rem_dashes "─")"╮$reset"
    else
        echo -e "$border╭"(string repeat -n $inner_w "─")"╮$reset"
    end
    
    function _row -S -V border -V reset -V dim -V val_w
        set -l label $argv[1]
        set -l color $argv[2]
        set -l raw_val (string trim -- "$argv[3]")

        if test -z "$raw_val"
            set -l pad (string repeat -n (math $val_w - 1) " ")
            printf "$border│$reset  \033[1m%-11s:\033[0m $dim—$reset%s$border│$reset\n" "$label" "$pad"
            return
        end

        set -l lines (echo "$raw_val" | fold -s -w $val_w)
        set -l first 1
        for l in $lines
            set -l cur_len (string length -- "$l")
            set -l pad_len (math $val_w - $cur_len)
            set -l pad (string repeat -n $pad_len " ")
            if test $first -eq 1
                printf "$border│$reset  \033[1m%-11s:\033[0m $color%s$reset%s$border│$reset\n" "$label" "$l" "$pad"
                set first 0
            else
                printf "$border│$reset               $color%s$reset%s$border│$reset\n" "$l" "$pad"
            end
        end
    end

    _row "Titolo" "\033[1;33m" "$title"
    _row "Autore" "\033[1;32m" "$author"
    _row "Inventario" "\033[1;36m" "$inv"
    _row "Dewey" "\033[1;35m" "$dewey"
    _row "Editore" "\033[0;37m" "$pub"
    _row "Soggetto" "\033[0;37m" "$subj"
    _row "Prezzo" "\033[0;37m" "$price"
    _row "Ubicazione" "\033[0;37m" "$loc"
    _row "Note" "\033[1;31m" "$notes"

    echo -e "$border╰"(string repeat -n $inner_w "─")"╯$reset"
end
