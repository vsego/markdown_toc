" Slugify selection

function! Slugify(text)
    " Lowercase text
    let l:result = substitute(a:text, '.*', '\L&', '')
    " Replace non-chars/digits with dashes
    let l:result = substitute(l:result, '\s\+', '-' ,'g')
    let l:result = substitute(l:result, '[^-_a-z0-9]\+', '' ,'g')
    " Strip leading and trailing dashes
    let l:result = substitute(l:result, '\v(^-+|-+$)', '' ,'g')
    return l:result
endfunction

function! Slurlify(text)
    return "[" . a:text . "](#" . Slugify(a:text) . ")"
endfunction

" MarkDown Table of Contents

function! MDtoc_save_desc(descriptions, slug, desc)
    if type(a:descriptions) == v:t_dict
        let a:descriptions[a:slug] = a:desc
    endif
    return ""
endfunction

function! MDtoc_match_toc_line(idx, descriptions)
    let l:m = matchlist(getline(a:idx), '\v^(\s{4})*\d+\.\s+\[.{-}\]\((.{-})\)(\s*-\s*(.{-}))?\s*$')
    if len(l:m) && type(a:descriptions) == v:t_dict
        let a:descriptions[l:m[2]] = l:m[4]
    endif
    return len(l:m)
endfunction

function! MDtoc_remove_toc(line_num)
    let l:curr = a:line_num
    let l:result = {}
    let l:moved = 0
    while l:curr > 0 && MDtoc_match_toc_line(l:curr, v:null) > 0
        let l:curr -= 1
        let l:moved = 1
    endwhile
    let l:curr += l:moved
    call cursor(l:curr, 1)
    while MDtoc_match_toc_line(l:curr, l:result) > 0
        d
    endwhile
    if l:curr == line(".")
        let l:curr -= 1
    elseif l:curr > line("$")
        let l:curr = line("$")
    endif
    return [l:result, l:curr]
endfunction

function! MDtoc_normalize_title(title)
    let l:result = a:title
    while 1
        let l:old = l:result
        let l:result = substitute(l:result, '\v!?\[([^\[]*)]\(.{-}\)', '\1', '')
        if l:old == l:result
            return l:result
        endif
    endwhile
endfunction

function! MDtoc_get_items(lines, fname, descriptions)
    let l:items = []
    let l:min_depth = v:none
    let l:in_code = 0
    for l:line in a:lines
        if l:line =~ '^```'
            let l:in_code = 1 - l:in_code
        endif
        if l:in_code == 1
            continue
        endif
        let l:m = matchlist(line, '^\v(#+)\s*(.{-})\s*$')
        if len(l:m)
            let l:depth = strlen(l:m[1])
            if l:min_depth is v:none || l:min_depth > l:depth
                let l:min_depth = l:depth
            endif
            let l:title = MDtoc_normalize_title(l:m[2])
            let l:link = a:fname . '#' . Slugify(l:title)
            let l:line = "[" . l:title . "](" . l:link . ")"
            if has_key(a:descriptions, l:link)
                let l:desc = remove(a:descriptions, l:link)
                if l:desc > ""
                    let l:line .= " - " . l:desc
                endif
            endif
            call add(l:items, [l:depth, l:line, l:title])
        endif
    endfor
    if len(l:items)
        if l:min_depth > 0
            for l:item in l:items
                let l:item[0] -= l:min_depth
            endfor
        endif
        let l:i = 0
        while l:items[l:i][0] > 0
            let l:i += 1
        endwhile
        if l:i > 0
            call remove(l:items, 0, l:i - 1)
        endif
    endif
    let l:result = []
    if len(l:items)
        let l:result_title = l:items[0][2]
    else
        let l:result_title = ""
    endif
    return [l:result_title, l:items]
endfunction

function! MDtoc_items_to_markdown(result, items, depth, idx)
    let l:prefix = repeat("    ", a:depth)
    let l:n = 0
    let l:idx = a:idx
    while l:idx < len(a:items)
        let [l:item_depth, l:line, l:title] = a:items[l:idx]
        if l:item_depth == a:depth
            let l:n += 1
            call add(a:result, l:prefix . l:n . ". " . l:line)
            let l:idx += 1
        elseif l:item_depth > a:depth
            let l:idx = MDtoc_items_to_markdown(a:result, a:items, a:depth + 1, l:idx)
        else
            return l:idx
        endif
    endwhile
    return l:idx
endfunction

function! MDtoc_add_descriptions(result, descriptions)
    for [l:slug, l:desc] in items(a:descriptions)
        if l:desc > ""
            call add(a:result, l:slug . " - " . l:desc)
        endif
    endfor
endfunction

function! MDtoc()
    let l:curr = line('.')
    let l:end = line("$")
    let [l:descriptions, l:curr] = MDtoc_remove_toc(l:curr)
    let [l:title, l:items] = MDtoc_get_items(getline(l:curr, l:end), "", l:descriptions)
    let l:result = []
    call MDtoc_items_to_markdown(l:result, l:items, 0, 0)
    call MDtoc_add_descriptions(l:result, l:descriptions)
    if len(l:result)
        call append(l:curr, l:result)
    else
        echohl WarningMsg
        echo "No ## headers in the line below the current one."
        echohl None
    endif
endfunction

function! MDtoc_get_file_toc(fpath, descriptions)
    let l:fname = fnamemodify(a:fpath, ':t')
    if l:fname == ""
        return ["", []]
    endif
    return MDtoc_get_items(readfile(a:fpath), l:fname, a:descriptions)
endfunction

function! MDtocd()
    let l:curr = line('.')
    let [l:descriptions, l:curr] = MDtoc_remove_toc(l:curr)
    let l:dir = expand('%:p:h')
    let l:curr_file = expand('%:p')
    if l:dir == "" || l:curr_file == ""
        echohl WarningMsg
        echo "The current file needs to be saved before using MDtocd."
        echohl None
    endif
    let l:data = []
    for l:fpath in split(glob(l:dir . "/*.md"), '\n')
        if l:fpath != l:curr_file
            let l:fname = fnamemodify(l:fpath, ':t')
            if l:fname !~ '^[._]'
                let l:fdata = MDtoc_get_file_toc(l:fpath, l:descriptions)
                if l:fdata[0] > "" && len(l:fdata[1]) > 0
                    call add(l:data, l:fdata)
                endif
            endif
        endif
    endfor
    let l:n = 0
    let l:items = []
    for [l:title, l:links] in sort(l:data)
        let l:n += 1
        call extend(l:items, l:links)
    endfor
    let l:result = []
    call MDtoc_items_to_markdown(l:result, l:items, 0, 0)
    call MDtoc_add_descriptions(l:result, l:descriptions)
    if len(l:result)
        call append(l:curr, l:result)
        call cursor(l:curr + len(l:result) + 1, 1)
    else
        echohl WarningMsg
        echo "No MarkDown (*.md) files with headers found in the current directory."
        echohl None
    endif
endfunction

command -range Slug :<line1>,<line2>s/\%V.*\%V./\=Slugify(submatch(0))/
command -range Slurl :<line1>,<line2>s/\%V.*\%V./\=Slurlify(submatch(0))/
command MDtoc :call MDtoc()
command MDtocd :call MDtocd()
