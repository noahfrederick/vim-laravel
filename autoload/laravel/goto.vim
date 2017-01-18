" autoload/laravel/goto.vim - Go to thing under cursor
" Maintainer: Noah Frederick

""
" @private
" Go to thing under cursor in PHP buffer
function! laravel#goto#filetype_php() abort
  let path = laravel#goto#view()
  if !empty(path) | return 'Eview '.path | endif

  let path = laravel#goto#config()
  if !empty(path) | return 'Econfig '.path | endif

  let path = laravel#goto#language()
  if !empty(path) | return 'Elanguage '.path | endif

  "TODO: composer class finder here

  return 'normal! gf'
endfunction

""
" @private
" Go to thing under cursor in Blade buffer
function! laravel#goto#filetype_blade() abort
  let path = laravel#goto#layout()
  if !empty(path) | return 'Eview '.path | endif

  let path = laravel#goto#include()
  if !empty(path) | return 'Econfig '.path | endif

  let path = laravel#goto#config()
  if !empty(path) | return 'Econfig '.path | endif

  let path = laravel#goto#language()
  if !empty(path) | return 'Elanguage '.path | endif

  "TODO: composer class finder here

  return 'normal! gf'
endfunction

""
" Find name in context
function! s:find_name(pattern) abort
  " Search position of thing on current line
  let [lnum, col] = searchpos(a:pattern, 'cnb', line('.'))
  let cursor = col('.')

  if col == 0
    return ''
  endif

  " Capture the name
  let buf = getline('.')[col - 1:]
  let name = substitute(buf, a:pattern, '\1', '')
  return s:path(name)
endfunction

""
" Convert name with dot notation to file path
function! s:path(name) abort
  return substitute(a:name, '\.', '/', 'g')
endfunction

""
" @private
" Capture config name at cursor
function! laravel#goto#config() abort
  return s:find_name('\<config([''"]\([^''"]\+\)[''"][,)].*$')
endfunction

""
" @private
" Capture view name at cursor
function! laravel#goto#view() abort
  return s:find_name('\<view([''"]\([^''"]\+\)[''"][,)].*$')
endfunction

""
" @private
" Capture include name at cursor
function! laravel#goto#include() abort
  return s:find_name('@include([''"]\([^''"]\+\)[''"][,)].*$')
endfunction

""
" @private
" Capture layout name at cursor
function! laravel#goto#layout() abort
  return s:find_name('@extends([''"]\([^''"]\+\)[''"][,)].*$')
endfunction

""
" @private
" Capture language name at cursor
function! laravel#goto#language() abort
  return s:find_name('\<trans\%(_choice\)\?([''"]\([^''"]\+\)[''"][,)].*$')
endfunction

""
" @private
" Hack for testing script-local functions.
function! laravel#goto#sid()
  nnoremap <SID> <SID>
  return maparg('<SID>', 'n')
endfunction

" vim: fdm=marker:sw=2:sts=2:et
