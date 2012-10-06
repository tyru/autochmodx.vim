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


command! -bar AutoChmodDisable let b:autochmodx_disable_autocmd = 1
command! -bar AutoChmodEnable  unlet! b:autochmodx_disable_autocmd
command! -bar AutoChmodRun call s:auto_chmod_run()

if !get(g:, 'authchmodx_no_autocmd')
    augroup autochmodx
        autocmd!
        autocmd BufWritePost *
        \   if !get(b:, 'autochmodx_disable_autocmd')
        \ |     call s:auto_chmod_run()
        \ | endif
    augroup END
endif

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

    " XXX: 'setlocal autoread' and
    " 'setglobal autoread' and
    " 'autocmd FileChangedShell' also do not work.
    " This is expected behavior?
    let save_global_autoread = &g:autoread
    let save_local_autoread  = &l:autoread
    set autoread
    try
        !chmod +x %
    catch
        return
    finally
        if save_global_autoread ==# save_local_autoread
            let &g:autoread = save_global_autoread
            set autoread<
        else
            let &l:autoread = save_local_autoread
            let &g:autoread = save_global_autoread
        endif
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
