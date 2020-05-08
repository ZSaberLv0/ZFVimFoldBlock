# ZFVimFoldBlock

vim script to fold code blocks using regexp

if you like my work, [check here](https://github.com/ZSaberLv0?utf8=%E2%9C%93&tab=repositories&q=ZFVim) for a list of my vim plugins


# preview

* see all virtual functions `:ZFFoldBlock //virtual/`

    ![example0](https://raw.githubusercontent.com/ZSaberLv0/ZFVimFoldBlock/master/example0.png)

* filter out all comments `:ZFFoldBlock /^[ \t]*#//`

    ![example1](https://raw.githubusercontent.com/ZSaberLv0/ZFVimFoldBlock/master/example1.png)

* fold by xml tags `:ZFFoldBlock /<([a-z0-9_:\.]+)/<\/\l1>|\/>/` (with `othree/eregex.vim`)

    ![example2](https://raw.githubusercontent.com/ZSaberLv0/ZFVimFoldBlock/master/example2.png)


# how to use

1. use [Vundle](https://github.com/VundleVim/Vundle.vim) or any other plugin manager is recommended

    ```
    Plugin 'ZSaberLv0/ZFVimFoldBlock'
    ```

    when `othree/eregex.vim` installed (recommended), perl style regexp would be used instead of vim style

    ```
    Plugin 'othree/eregex.vim'
    ```

1. `foldmethod` must be set to `manual`

    ```
    set foldmethod = manual
    ```

    by default, `foldmethod` would be set to `manual` when `ZFFoldBlock` called,
    you may disable it by `let g:ZFVimFoldBlock_resetFoldmethodWhenUse=0`

1. `foldminlines` recommended set to `0`, which allow fold even for single line

    ```
    set foldminlines=0
    ```

    by default, `foldminlines` would be set to `0` when `ZFFoldBlock` called,
    you may disable it by `let g:ZFVimFoldBlock_resetFoldminlinesWhenUse=0`

1. recommended to have these key map:

    ```
    nnoremap ZB q::call ZF_FoldBlockTemplate()<cr>
    nnoremap ZF :ZFFoldBlock //<left>
    ```

1. or, use the functions directly:

    ```
    " fold by begin and end regexp
    :ZFFoldBlock /begin_regexp/end_regexp/

    " same as :ZFFoldBlock /regexp//
    :ZFFoldIfMatch regexp

    " same as :ZFFoldBlock //regexp/
    :ZFFoldIfNotMatch regexp
    ```


# sample

you may `:call ZF_FoldBlockHelp()` to show sample at any time

* `/{/}/`              : normal block mode

    ```
    {
        in fold 1
        {
            in fold 2
        }
        in fold 1
    }
    ```

* `/rem//`             : fold if match

    ```
    rem in fold
    rem in fold
    ```

* `//rem/`             : fold if not match

    ```
    in fold
    in fold
    rem not in fold
    rem not in fold
    ```

* `/tag/tag/`          : single tag mode

    ```
    tag
        in fold 1
    tag
    not in fold
    tag
        in fold 2
    tag
    ```


# regexp

use vim's regexp by default, see `:h magic`

if you have [othree/eregex.vim](https://github.com/othree/eregex.vim) installed,
then perl style regexp would be used instead

you may force disable it by `let g:ZFVimFoldBlock_disableE2v = 1`


# advanced

* typical advanced usage:

    ```
    " fold comments accorrding to file type
    function! ZF_Plugin_ZFVimFoldBlock_comment()
        let expr='\(^\s*\/\/\)'
        if &filetype=='vim'
            let expr.='\|\(^\s*"\)'
        endif
        if &filetype=='c' || &filetype=='cpp'
            let expr.='\|\(^\s*\(\(\/\*\)\|\(\*\)\)\)'
        endif
        if &filetype=='make'
            let expr.='\|\(^\s*#\)'
        endif
        let disableE2vSaved = g:ZFVimFoldBlock_disableE2v
        let g:ZFVimFoldBlock_disableE2v = 1
        call ZF_FoldBlock("/" . expr . "//")
        let g:ZFVimFoldBlock_disableE2v = disableE2vSaved
        echo "comments folded"
    endfunction
    nnoremap ZC :call ZF_Plugin_ZFVimFoldBlock_comment()<cr>
    ```

* calling `ZFFoldBlock` would append fold instead of replace,
    before using the function,
    you may want to remove all fold by `zE` or `zD` manually

* when fold with `/expr_l/expr_r/` format,
    there's a special pattern for `expr_r` to reference submatches in `expr_l`
    (similar to `:h /\1`),
    the pattern format is `\lN`,
    where `N` is `1~9`

    for example, `/<([a-z]+)>/</\l1>/` would result:

    ```
    xxx   // not in fold
    <aa>  // in fold
      xxx // in fold
    </aa> // in fold
    xxx   // not in fold
    ```

