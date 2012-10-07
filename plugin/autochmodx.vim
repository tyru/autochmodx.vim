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


command! -bar -bang AutoChmodDisable
\   let {<bang>0 ? "g" : "b"}:autochmodx_disable_autocmd = 1

command! -bar AutoChmodEnable
\   unlet! g:autochmodx_disable_autocmd
\          b:autochmodx_disable_autocmd

command! -bar AutoChmodRun
\   call autochmodx#make_it_executable()

command! -bar AutoChmodRunAutocmd
\   if !get(g:, 'autochmodx_disable_autocmd')
\   && !get(b:, 'autochmodx_disable_autocmd')
\ |     call autochmodx#make_it_executable()
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


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
