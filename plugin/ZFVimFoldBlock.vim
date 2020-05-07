
" whether disable E2v, 0 or 1
if !exists('g:ZFVimFoldBlock_disableE2v')
    let g:ZFVimFoldBlock_disableE2v = 0
endif

" whether auto set foldmethod to manual, 0 or 1
if !exists('g:ZFVimFoldBlock_resetFoldmethodWhenUse')
    let g:ZFVimFoldBlock_resetFoldmethodWhenUse = 1
endif

" whether auto set foldminlines to 0, 0 or 1
if !exists('g:ZFVimFoldBlock_resetFoldminlinesWhenUse')
    let g:ZFVimFoldBlock_resetFoldminlinesWhenUse = 1
endif

" reserve how many lines for each match
if !exists('g:ZFVimFoldBlock_reserveLine')
    let g:ZFVimFoldBlock_reserveLine = {
                \   'foldIfMatch' : {
                \     'l' : 0,
                \     'r' : 0,
                \   },
                \   'foldIfNotMatch' : {
                \     'l' : 0,
                \     'r' : 0,
                \   },
                \   'foldSingleTag' : {
                \     'l' : 1,
                \     'r' : 0,
                \   },
                \   'foldBlock' : {
                \     'l' : 1,
                \     'r' : 0,
                \   },
                \ }
endif

" fold block by regexp
function! s:ZF_FoldBlockHasE2v()
    if g:ZFVimFoldBlock_disableE2v
        return 0
    endif

    try
        call E2v(".")
        return 1
    catch
        return 0
    endtry
endfunction

function! ZF_FoldBlockHelp()
    echo "sample: /from/to/[comment]"
    echo "multiline supported, use \\n for linebreak"
    echo "valid mode:"
    echo "    /{/}/         : normal block mode"
    echo "        {"
    echo "            in fold 1"
    echo "            {"
    echo "                in fold 2"
    echo "            }"
    echo "            in fold 1"
    echo "        }"
    echo "    /rem//        : fold if match"
    echo "        rem in fold"
    echo "        rem in fold"
    echo "    //rem/        : fold if not match"
    echo "        in fold"
    echo "        in fold"
    echo "        rem not in fold"
    echo "        rem not in fold"
    echo "    /tag/tag/     : single tag mode"
    echo "        tag"
    echo "            in fold 1"
    echo "        tag"
    echo "        not in fold"
    echo "        tag"
    echo "            in fold 2"
    echo "        tag"
endfunction

function! ZF_FoldBlock(expr)
    let expr = a:expr
    let expr = substitute(expr, '\\\\', '_t_bslash_t_', 'g')
    let expr = substitute(expr, '\\/', '_t_slash_t_', 'g')
    let expr = substitute(expr, '\\\$', '_t_dollar_t_', 'g')
    let exprList = split(expr, '/', 1)
    let expr_l = exprList[1]
    let expr_r = exprList[2]

    let expr_l = substitute(expr_l, '_t_bslash_t_', '\\\\', 'g')
    let expr_r = substitute(expr_r, '_t_bslash_t_', '\\\\', 'g')
    let expr_l = substitute(expr_l, '_t_slash_t_', '\\/', 'g')
    let expr_r = substitute(expr_r, '_t_slash_t_', '\\/', 'g')

    if s:ZF_FoldBlockHasE2v()
        let expr_l = E2v(expr_l)
        let expr_r = E2v(expr_r)
    endif
    let expr_l = substitute(expr_l, '\$', '\\%(\\n\\|$\\)\\@=', 'g') " (?=\n|$)
    let expr_r = substitute(expr_r, '\$', '\\%(\\n\\|$\\)\\@=', 'g') " \%(\n\|$\)\@=
    let expr_l = substitute(expr_l, '_t_dollar_t_', '\\\$', 'g')
    let expr_r = substitute(expr_r, '_t_dollar_t_', '\\\$', 'g')
    if !empty(expr_l) && expr_l[0] != '^'
        let expr_l = '^[^\n]\{-}' . expr_l " ^[^\n]*?
    endif
    if !empty(expr_r) && expr_r[0] != '^'
        let expr_r = '^[^\n]\{-}' . expr_r
    endif

    if strlen(expr_l) == 0 && strlen(expr_r) == 0
        echo "invalid expr"
        call ZF_FoldBlockHelp()
        return
    endif

    if g:ZFVimFoldBlock_resetFoldminlinesWhenUse && &foldminlines != "0"
        set foldminlines=0
    endif

    if g:ZFVimFoldBlock_resetFoldmethodWhenUse && &foldmethod != "manual"
        set foldmethod=manual
        normal! zE
    endif

    let lines = getline(1, '$')
    if len(lines) <= 1
        return
    endif
    let contents = join(lines, "\n")
    let lineOffsets = [0]
    let lineOffsetsPrev = 0
    for line in lines
        let lineOffsetsPrev += len(line) + 1 " +1 for `\n`
        call add(lineOffsets, lineOffsetsPrev)
    endfor

    if empty(expr_r)
        call s:foldIfMatch(lines, contents, lineOffsets, expr_l)
    elseif empty(expr_l)
        call s:foldIfNotMatch(lines, contents, lineOffsets, expr_r)
    elseif expr_l == expr_r
        call s:foldSingleTag(lines, contents, lineOffsets, expr_l)
    else
        call s:foldBlock(lines, contents, lineOffsets, expr_l, expr_r)
    endif
endfunction
function! s:match(lines, contents, lineOffsets, iLine, expr)
    let start = match(a:contents, a:expr, a:lineOffsets[a:iLine])
    if start >= 0
        let end = matchend(a:contents, a:expr, a:lineOffsets[a:iLine])
        if end >= 0
            return {
                        \   'start' : s:posToLine(a:lines, a:contents, a:lineOffsets, start),
                        \   'end' : s:posToLine(a:lines, a:contents, a:lineOffsets, end),
                        \ }
        endif
    endif
    return {}
endfunction
function! s:posToLine(lines, contents, lineOffsets, pos)
    let i = len(a:lineOffsets) - 1
    while a:pos < a:lineOffsets[i]
        let i -= 1
    endwhile
    return i
endfunction
function! s:exprBackRef(expr, matchlist)
    let expr = a:expr
    let expr = substitute(expr, '\\l1', a:matchlist[1], 'g')
    let expr = substitute(expr, '\\l2', a:matchlist[2], 'g')
    let expr = substitute(expr, '\\l3', a:matchlist[3], 'g')
    let expr = substitute(expr, '\\l4', a:matchlist[4], 'g')
    let expr = substitute(expr, '\\l5', a:matchlist[5], 'g')
    let expr = substitute(expr, '\\l6', a:matchlist[6], 'g')
    let expr = substitute(expr, '\\l7', a:matchlist[7], 'g')
    let expr = substitute(expr, '\\l8', a:matchlist[8], 'g')
    let expr = substitute(expr, '\\l9', a:matchlist[9], 'g')
    return expr
endfunction
function! s:doFold(iL, iR)
    if a:iL > a:iR
        return
    endif
    if a:iL == a:iR && getline(a:iL + 1) == ''
        return
    endif
    execute ":" . (a:iL+1) . "," . (a:iR+1) . "fold"
    execute ":" . (a:iL+1) . "," . (a:iR+1) . "foldclose!"
endfunction

function! s:foldIfMatch(lines, contents, lineOffsets, expr)
    let reserve_l = g:ZFVimFoldBlock_reserveLine['foldIfMatch']['l']
    let reserve_r = g:ZFVimFoldBlock_reserveLine['foldIfMatch']['r']
    let i = 0
    let iEnd = len(a:lines)
    let prev = -1
    while i < iEnd
        let match = s:match(a:lines, a:contents, a:lineOffsets, i, a:expr)
        if empty(match)
            if prev == -1
                let i += 1
            else
                call s:doFold(prev + reserve_l, i - 1 - reserve_r)
                let prev = -1
                let i += 1
            endif
        else
            if prev == -1
                let prev = match['start']
                let i = match['end'] + 1
            else
                let i = match['end'] + 1
            endif
        endif
    endwhile
    if prev != -1
        call s:doFold(prev + reserve_l, iEnd - 1 - reserve_r)
    endif
endfunction

function! s:foldIfNotMatch(lines, contents, lineOffsets, expr)
    let reserve_l = g:ZFVimFoldBlock_reserveLine['foldIfNotMatch']['l']
    let reserve_r = g:ZFVimFoldBlock_reserveLine['foldIfNotMatch']['r']
    let i = 0
    let iEnd = len(a:lines)
    let prev = -1
    while i < iEnd
        let match = s:match(a:lines, a:contents, a:lineOffsets, i, a:expr)
        if empty(match)
            if prev == -1
                let prev = i
                let i += 1
            else
                let i += 1
            endif
        else
            if prev == -1
                let i = match['end'] + 1
            else
                call s:doFold(prev + reserve_l, match['start'] - 1 - reserve_r)
                let prev = -1
                let i = match['end'] + 1
            endif
        endif
    endwhile
    if prev != -1
        call s:doFold(prev + reserve_l, iEnd - 1 - reserve_r)
    endif
endfunction

function! s:foldSingleTag(lines, contents, lineOffsets, expr)
    let reserve_l = g:ZFVimFoldBlock_reserveLine['foldSingleTag']['l']
    let reserve_r = g:ZFVimFoldBlock_reserveLine['foldSingleTag']['r']
    let i = 0
    let iEnd = len(a:lines)
    let prev = -1
    while i < iEnd
        let match = s:match(a:lines, a:contents, a:lineOffsets, i, a:expr)
        if empty(match)
            let i += 1
        else
            if prev == -1
                let prev = match['start']
                let i = match['end'] + 1
            else
                call s:doFold(prev + reserve_l, match['end'] - reserve_r)
                let prev = -1
                let i = match['end'] + 1
            endif
        endif
    endwhile
    if prev != -1
        call s:doFold(prev + reserve_l, iEnd - 1 - reserve_r)
    endif
endfunction

function! s:foldBlock(lines, contents, lineOffsets, expr_l, expr_r)
    let reserve_l = g:ZFVimFoldBlock_reserveLine['foldBlock']['l']
    let reserve_r = g:ZFVimFoldBlock_reserveLine['foldBlock']['r']
    let i = 0
    let iEnd = len(a:lines)
    " [
    "   {
    "     'start' : '',
    "     'end' : '',
    "     'iLine' : '',
    "     'matchlist' : [],
    "   },
    " ]
    let prev = []
    while i < iEnd
        let iNext = i + 1
        let match_l = s:match(a:lines, a:contents, a:lineOffsets, i, a:expr_l)
        if !empty(match_l)
            let match_l['iLine'] = i
            let match_l['matchlist'] = matchlist(a:contents, a:expr_l, a:lineOffsets[i])
            call add(prev, match_l)
            let iNext = match_l['end'] + 1
        endif
        if empty(prev)
            let i += 1
            continue
        endif

        let match_l = prev[-1]
        let expr_r = s:exprBackRef(a:expr_r, match_l['matchlist'])
        let match_r = s:match(a:lines, a:contents, a:lineOffsets, i, expr_r)
        if empty(match_r)
            let i = iNext
            continue
        endif
        if match_l['iLine'] == i
            let iL = match_l['start'] < match_r['start'] ? match_l['start'] : match_r['start']
            let iR = match_l['end'] > match_r['end'] ? match_l['end'] : match_r['end']
            call s:doFold(iL + reserve_l, iR - reserve_r)
            call remove(prev, -1)
            let i = iR + 1
            continue
        endif
        call s:doFold(match_l['start'] + reserve_l, match_r['end'] - reserve_r)
        call remove(prev, -1)
        let i = match_r['end'] + 1
    endwhile
    while !empty(prev)
        let match_l = remove(prev, -1)
        call s:doFold(match_l['start'] + reserve_l, iEnd - 1 - reserve_r)
    endwhile
endfunction

function! ZF_FoldBlockTemplate()
    let t = ''

    if s:ZF_FoldBlockHasE2v()
        let t .= "\n" . 'ZFFoldBlock /^[ \t]*rem//           "fold rem"'
        let t .= "\n" . 'ZFFoldBlock /^[ \t]*#//             "fold #"'
        let t .= "\n" . 'ZFFoldBlock /\/\*/\*\//             "fold /* */"'
        let t .= "\n" . 'ZFFoldBlock /^[ \t]*\/\///          "fold //"'
        let t .= "\n" . 'ZFFoldBlock //                      "custom regexp (perl syntax)"'
        let t .= "\n" . 'ZFFoldBlock /\{/\}/                 "fold {}"'
        let t .= "\n" . ''
    else
        let t .= "\n" . 'ZFFoldBlock /^[ \t]*rem//           "fold rem"'
        let t .= "\n" . 'ZFFoldBlock /^[ \t]*#//             "fold #"'
        let t .= "\n" . 'ZFFoldBlock /\/\*/\*\//             "fold /* */"'
        let t .= "\n" . 'ZFFoldBlock /^[ \t]*\/\///          "fold //"'
        let t .= "\n" . 'ZFFoldBlock //                      "custom regexp (vim syntax)"'
        let t .= "\n" . 'ZFFoldBlock /{/}/                   "fold {}"'
        let t .= "\n" . ''
    endif

    let s = @t
    let @t = t
    normal! "tPG5kwl
    let @t = s
endfunction

command! -nargs=+ ZFFoldBlock :call ZF_FoldBlock(<q-args>)
command! -nargs=+ ZFFoldIfMatch :call ZF_FoldBlock('/' . <q-args> . '//')
command! -nargs=+ ZFFoldIfNotMatch :call ZF_FoldBlock('//' . <q-args> . '/')

