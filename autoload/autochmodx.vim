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


" Functions {{{1

function! autochmodx#make_it_executable() "{{{
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
    call s:echomsg('Special', 'chmod +x '.expand('%').' ... done.')
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
