" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}



" Utility functions {{{1

function! s:echomsg(hl, msg) "{{{
    execute 'echohl' a:hl
    try
        echomsg a:msg
    finally
        echohl None
    endtry
endfunction "}}}


" Validate global variables. {{{1

if !exists('g:autochmodx_chmod_opt')
    call s:echomsg('Error',
    \   'autochmodx: error: '
    \   . 'g:autochmodx_chmod_opt is not found...')
    let s:autochmodx_disable = 1
endif

function s:check_chmod_opt(opt) "{{{
    return a:opt =~# '^[ugoa]*+x$'
endfunction "}}}
function! s:validate_chmod_opt(opt) "{{{
    if !s:check_chmod_opt(a:opt)
        call s:echomsg('Error', "autochmodx: error: '".a:opt."' is invalid argument for chmod. disable plugin.")
        let s:autochmodx_disable = 1
    endif
endfunction "}}}
call s:validate_chmod_opt(g:autochmodx_chmod_opt)


" Functions {{{1

function! autochmodx#make_it_executable() "{{{
    if get(s:, 'autochmodx_disable')
        call s:echomsg('WarningMsg', "autochmodx is disabled.")
        return
    endif
    if !s:check_auto_chmod()
        return
    endif

    try
        silent execute '!chmod '.g:autochmodx_chmod_opt.' %'
        " Reload buffer.
        silent edit
        " Load syntax.
        syntax enable
    catch
        return
    endtry

    " Disable auto-commands when 'chmod +x' succeeded.
    let b:autochmodx_disable_autocmd = 1

    redraw
    call s:echomsg('Special', 'chmod '.g:autochmodx_chmod_opt.' '.expand('%').' ... done.')
    sleep 1
endfunction "}}}

function! s:check_auto_chmod() "{{{
    return !&modified
    \   && filewritable(expand('%'))
    \   && getfperm(expand('%'))[2] !=# 'x'
    \   && getline(1) =~# '^#!'
endfunction "}}}

" }}}1


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
