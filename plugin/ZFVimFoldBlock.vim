" ZFVimFoldBlock.vim - fold code blocks by regexp
" Author:  ZSaberLv0 <http://zsaber.com/>

let g:ZFVimFoldBlock_loaded = 1

" whether disable E2v, 0 or 1
let g:ZFVimFoldBlock_disableE2v = 0
" whether auto set foldmethod to manual, 0 or 1
let g:ZFVimFoldBlock_resetFoldmethodWhenUse = 1

" fold block by regexp
function! s:ZF_FoldBlockHasE2v()
    if g:ZFVimFoldBlock_disableE2v
        return 0
    endif

    try
        let dummy=E2v(".")
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
    let expr = substitute(expr, '\\n', '\n', 'g')
    let expr = substitute(expr, '\\/', '_t_slash_t_', 'g')
    let exprList = split(expr, '/', 1)

    let expr_l = exprList[1]
    let expr_l = substitute(expr_l, '_t_bslash_t_', '\\\\', 'g')
    let expr_l = substitute(expr_l, '_t_slash_t_', '\\/', 'g')

    let expr_r = exprList[2]
    let expr_r = substitute(expr_r, '_t_bslash_t_', '\\\\', 'g')
    let expr_r = substitute(expr_r, '_t_slash_t_', '\\/', 'g')

    if s:ZF_FoldBlockHasE2v()
        let expr_l = E2v(expr_l)
        let expr_r = E2v(expr_r)
    endif

    if strlen(expr_l) == 0 && strlen(expr_r) == 0
        echo "invalid expr"
        call ZF_FoldBlockHelp()
        return
    endif

    if g:ZFVimFoldBlock_resetFoldmethodWhenUse && &foldmethod != "manual"
        set foldmethod=manual
        normal! zE
    endif

    let multiline_l = len(split(expr_l, "\n")) - 1
    let multiline_r = len(split(expr_r, "\n")) - 1

    if strlen(expr_l) == 0
        let revert_mode = 1
        let expr_l = expr_r
    else
        let revert_mode = 0
    endif
    let single_mode = (strlen(expr_r) == 0)

    let start = []
    let i = 1
    let totalLine = line("$")
    for iTmp in range(totalLine)
        let i = iTmp + 1

        let line_l = getline(i)
        let iMultiline = 0
        while iMultiline < multiline_l && i + iMultiline <= totalLine
            let iMultiline = iMultiline + 1
            let line_l = line_l . "\n" . getline(i + iMultiline)
        endwhile
        let match_l = match(line_l, expr_l)

        if single_mode
            if len(start) <= 0
                if match_l != -1
                    call add(start, i)
                endif
            else
                if match_l == -1
                    if start[-1] <= i - 1
                        execute ":" . start[-1] . "," . (i - 1) . "fold"
                        execute ":" . start[-1] . "," . (i - 1) . "foldclose!"
                    endif
                    call remove(start, -1)
                endif
            endif
            continue
        endif

        if revert_mode
            if match_l == -1
                if len(start) <= 0
                    call add(start, i)
                endif
            else
                if len(start) > 0
                    if start[-1] <= i - 1
                        execute ":" . start[-1] . "," . (i - 1) . "fold"
                        execute ":" . start[-1] . "," . (i - 1) . "foldclose!"
                    endif
                    call remove(start, -1)
                endif
            endif
            continue
        endif

        let line_r = getline(i)
        let iMultiline = 0
        while iMultiline < multiline_r && i + iMultiline <= totalLine
            let iMultiline = iMultiline + 1
            let line_r = line_r . "\n" . getline(i + iMultiline)
        endwhile
        let match_r = match(line_r, expr_r)

        if expr_l != expr_r && match_l != -1 && match_r != -1
            continue
        elseif match_r != -1 && len(start) > 0
            if start[-1] <= i
                execute ":" . start[-1] . "," . i . "fold"
                execute ":" . start[-1] . "," . i . "foldclose!"
            endif
            call remove(start, -1)
        elseif match_l != -1
            if match_l != 0
                call add(start, i + 1)
            else
                call add(start, i)
            endif
        endif
    endfor

    if (single_mode || revert_mode) && len(start) > 0 && start[-1] <= i
        execute ":" . start[-1] . "," . i . "fold"
        execute ":" . start[-1] . "," . i . "foldclose!"
    endif
endfunction
function! ZF_FoldBlockTemplate()
    let t = ''

    if s:ZF_FoldBlockHasE2v()
        let t .= '_foldblock_n_ ZFFoldBlock /^[ \t]*rem//           "fold rem"'
        let t .= '_foldblock_n_ ZFFoldBlock /^[ \t]*#//             "fold #"'
        let t .= '_foldblock_n_ ZFFoldBlock /^[ \t]*\/\*/\*\//      "fold /* */"'
        let t .= '_foldblock_n_ ZFFoldBlock /^[ \t]*\/\///          "fold //"'
        let t .= '_foldblock_n_ ZFFoldBlock //                      "custom regexp (perl syntax)"'
        let t .= '_foldblock_n_ ZFFoldBlock /.{0}{/ {0}}/           "fold {}"'
        let t .= '_foldblock_n_ ZFFoldBlock /.{4}{/ {4}}/           "fold     {}"'
        let t .= '_foldblock_n_ ZFFoldBlock /.{8}{/ {8}}/           "fold         {}"'
        let t .= '_foldblock_n_ ZFFoldBlock /(?<=^[ \t]*#[ \t]*((if)|(el)).*\n).*/.*\n[ \t]*#[ \t]*((el)|(end))/'
        let t .= '_foldblock_n_                                     "fold #if #else #endif"'
        let t .= '_foldblock_n_ '
    else
        let t .= '_foldblock_n_ ZFFoldBlock /^[ \t]*rem//           "fold rem"'
        let t .= '_foldblock_n_ ZFFoldBlock /^[ \t]*#//             "fold #"'
        let t .= '_foldblock_n_ ZFFoldBlock /^[ \t]*\/\*/\*\//      "fold /* */"'
        let t .= '_foldblock_n_ ZFFoldBlock /^[ \t]*\/\///          "fold //"'
        let t .= '_foldblock_n_ ZFFoldBlock //                      "custom regexp (vim syntax)"'
        let t .= '_foldblock_n_ ZFFoldBlock /.\{0}{/ \{0}}/         "fold {}"'
        let t .= '_foldblock_n_ ZFFoldBlock /.\{4}{/ \{4}}/         "fold     {}"'
        let t .= '_foldblock_n_ ZFFoldBlock /.\{8}{/ \{8}}/         "fold         {}"'
        let t .= '_foldblock_n_ ZFFoldBlock /\%(^[ \t]*#[ \t]*\(\(if\)\|\(el\)\).*\n\)\@<=.*/.*\n[ \t]*#[ \t]*\(\(el\)\|\(end\)\)/'
        let t .= '_foldblock_n_                                     "fold #if #else #endif"'
        let t .= '_foldblock_n_ '
    endif

    let t = substitute(t, '_foldblock_n_ ', '\n', 'g')
    let @t = t
    normal! "tPG5kwl
endfunction

command! -nargs=+ ZFFoldBlock :call ZF_FoldBlock(<q-args>)
command! -nargs=+ ZFFoldIfMatch :call ZF_FoldBlock('/' . <q-args> . '//')
command! -nargs=+ ZFFoldIfNotMatch :call ZF_FoldBlock('//' . <q-args> . '/')

