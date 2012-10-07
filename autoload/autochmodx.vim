" vim:foldmethod=marker:fen:
scriptencoding utf-8

" :finish when non-Unix environment or chmod is not in PATH {{{
if !has('unix') || !executable('chmod')
    finish
endif
" }}}
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}
" Load plugin/autochmodx.vim at first {{{
if !exists('g:loaded_autochmodx')
    runtime! plugin/autochmodx.vim
endif
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

function! s:any(func_list, args) "{{{
    for F in a:func_list
        if call(F, a:args)
            return 1
        endif
        unlet! F
    endfor
    return 0
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


" Variables {{{1

let s:scriptish_detectors = []


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
    let bufnr = bufnr('%')
    let file  = expand('%')
    return !&modified
    \   && filewritable(file)
    \   && getfperm(file)[2] !=# 'x'
    \   && (getline(1) =~# '^#!' || s:any(s:scriptish_detectors, [bufnr, file]))
endfunction "}}}

function! autochmodx#register_scriptish_detector(Func) "{{{
    if !s:is_function(a:Func)
        call s:echomsg('Error', 'autochmodx: error: '
        \   . 'not valid value for '
        \   . 'autochmodx#register_scriptish_detector().')
        return
    endif

    call add(s:scriptish_detectors, a:Func)
endfunction "}}}

function! s:is_function(Func) "{{{
    return type(a:Func) is type(function('tr'))
    \   || type(a:Func) is type("") && exists('*'.a:Func)
endfunction "}}}

" }}}1


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
