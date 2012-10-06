" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Load Once {{{
if (exists('g:loaded_autochmodx') && g:loaded_autochmodx) || &cp
    finish
endif
let g:loaded_autochmodx = 1
" }}}
" :finish when non-Unix environment or chmod is not in PATH {{{
if !has('unix') || !executable('chmod')
    finish
endif
" }}}
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


let g:autochmodx_chmod_opt = get(g:, 'autochmodx_chmod_opt', '+x')


command! -bar AutoChmodDisable
\   let b:autochmodx_disable_autocmd = 1
command! -bar AutoChmodEnable
\   unlet! b:autochmodx_disable_autocmd
command! -bar AutoChmodRun
\   call s:auto_chmod_run()
command! -bar AutoChmodRunAutocmd
\   if !get(b:, 'autochmodx_disable_autocmd')
\ |     call s:auto_chmod_run()
\ | endif


augroup autochmodx
    autocmd!
    if !get(g:, 'autochmodx_no_BufWritePost_autocmd')
        autocmd BufWritePost * AutoChmodRunAutocmd
    endif
    if !get(g:, 'autochmodx_no_CursorHold_autocmd')
        autocmd CursorHold * AutoChmodRunAutocmd
    endif
augroup END


function! s:check_auto_chmod() "{{{
    return !&modified
    \   && filewritable(expand('%'))
    \   && getfperm(expand('%'))[2] !=# 'x'
    \   && getline(1) =~# '^#!'
endfunction "}}}

function! s:auto_chmod_run() "{{{
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

function! s:echomsg(hl, msg) "{{{
    execute 'echohl' a:hl
    try
        echomsg a:msg
    finally
        echohl None
    endtry
endfunction "}}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
