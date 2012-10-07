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


" Global variables {{{1

let g:autochmodx_chmod_opt = get(g:, 'autochmodx_chmod_opt', '+x')
let g:autochmodx_scriptish_file_patterns =
\   get(g:, 'autochmodx_scriptish_file_patterns', []) + [
\      '\c.*\.pl$',
\      '\c.*\.rb$',
\      '\c.*\.py$',
\      '\c.*\.sh$',
\   ]
let g:autochmodx_ignore_scriptish_file_patterns =
\   get(g:, 'autochmodx_ignore_scriptish_file_patterns', [])


" Utility functions {{{1

function! s:echomsg(hl, msg) "{{{
    execute 'echohl' a:hl
    try
        echomsg a:msg
    finally
        echohl None
    endtry
endfunction "}}}

function! s:any(list, expr) "{{{
    for Val in a:list
        let val = Val    " alias
        if eval(a:expr)
            return 1
        endif
        unlet! Val val
    endfor
    return 0
endfunction "}}}


" Validate global variables. {{{1

function! s:initialize_variables() "{{{
    call s:validate_chmod_opt(g:autochmodx_chmod_opt)
    call autochmodx#register_scriptish_detector(
    \   'autochmodx#detect_scriptish_by_content'
    \)
endfunction "}}}

" g:autochmodx_chmod_opt {{{2

function! s:check_chmod_opt(opt) "{{{
    return a:opt =~# '^[ugoa]*+x$'
endfunction "}}}
function! s:validate_chmod_opt(opt) "{{{
    if !s:check_chmod_opt(a:opt)
        call s:echomsg('Error', "autochmodx: error: '".a:opt."' is invalid argument for chmod. disable plugin.")
        let s:autochmodx_disable = 1
    endif
endfunction "}}}

" }}}2


" Variables {{{1

let s:scriptish_detectors = []
let s:variables_were_initialized = 0


" Functions {{{1

function! autochmodx#make_it_executable() "{{{
    if !s:variables_were_initialized
        call s:initialize_variables()
        let s:variables_were_initialized = 1
    endif

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
    let file  = expand('%:p')
    if &modified
    \   || !filewritable(file)
    \   || getfperm(file)[2] ==# 'x'
        return 0
    endif

    if s:any(
    \   g:autochmodx_ignore_scriptish_file_patterns,
    \   string(file).' =~# val'
    \)
        return 0
    endif

    if s:any(
    \       s:scriptish_detectors,
    \       'call(Val, ['.bufnr.', '.string(file).'])'
    \   )
    \   || s:any(
    \           g:autochmodx_scriptish_file_patterns,
    \           string(file).' =~# val'
    \   )
        return 1
    endif

    return 0
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

function! autochmodx#detect_scriptish_by_content(bufnr, file) "{{{
    return getbufline(a:bufnr, 1)[0] =~# '^#!'
endfunction "}}}

" }}}1


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
