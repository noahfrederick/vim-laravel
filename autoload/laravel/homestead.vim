" autoload/laravel/homestead.vim - Laravel Homestead support for Vim
" Maintainer: Noah Frederick

""
" The directory where Homestead is installed.
let s:dir = get(g:, 'laravel_homestead_dir', '~/Homestead')
let s:yaml = s:dir . '/Homestead.yaml'
let s:json = s:dir . '/Homestead.json'

""
" Get Dict from JSON {expr}.
function! s:json_decode(expr) abort
  try
    if exists('*json_decode')
      let expr = type(a:expr) == type([]) ? join(a:expr, "\n") : a:expr
      return json_decode(expr)
    else
      return projectionist#json_parse(a:expr)
    endif
  catch /^Vim\%((\a\+)\)\=:E474/
    call laravel#error('Homestead.json cannot be parsed')
  catch /^invalid JSON/
    call laravel#error('Homestead.json cannot be parsed')
  catch /^Vim\%((\a\+)\)\=:E117/
    call laravel#error('projectionist is not available')
  endtry
  return {}
endfunction

""
" Get path to current project on the Homestead VM.
function! laravel#homestead#root(app_root) abort
  if !filereadable(s:json)
    call laravel#error('Homestead.json cannot be read: '
          \ . s:json . ' (set g:laravel_homestead_dir)')
    return ''
  endif

  let config = s:json_decode(readfile(s:json))

  for folder in get(config, 'folders', [])
    let source = expand(folder.map)

    if a:app_root . '/' =~# '^' . source . '/'
      return substitute(a:app_root, '^' . source, folder.to, '')
    endif
  endfor

  return ''
endfunction

""
" Change working directory to {dir}, respecting current window's local dir
" state. Returns old working directory to be restored later by a second
" invocation of the function.
function! s:cd(dir) abort
  let cd = exists('*haslocaldir') && haslocaldir() ? 'lcd' : 'cd'
  let cwd = getcwd()
  execute cd fnameescape(a:dir)
  return cwd
endfunction

""
" Build SSH shell command from command-line arguments.
function! s:ssh(args) abort
  if empty(a:args)
    return 'vagrant ssh'
  endif

  let root = laravel#app().homestead_path()

  if empty(root)
    call laravel#error('Homestead site not configured for '
          \ . laravel#app().path())
    return ''
  endif

  let args = insert(a:args, 'cd ' . fnamemodify(root, ':S') . ' &&')
  return 'vagrant ssh -- ' . shellescape(join(args))
endfunction

""
" Build Vagrant shell command from command-line arguments.
function! s:vagrant(args) abort
  let args = empty(a:args) ? ['status'] : a:args
  return 'vagrant ' . join(args)
endfunction

""
" The :Homestead command.
function! laravel#homestead#exec(...) abort
  let args = copy(a:000)
  let vagrant = remove(args, 0)

  if !isdirectory(s:dir)
    return laravel#error('Homestead directory does not exist: '
          \ . s:dir . ' (set g:laravel_homestead_dir)')
  endif

  let cmdline = vagrant ==# '!' ? s:vagrant(args) : s:ssh(args)

  if empty(cmdline)
    " There is no path configured for the VM.
    return ''
  endif

  if exists(':Start')
    execute 'Start -title=homestead -wait=always -dir='.fnameescape(s:dir) cmdline
  elseif exists(':terminal')
    tab split
    execute 'lcd' fnameescape(s:dir)
    execute 'terminal' cmdline
  else
    let cwd = s:cd(s:dir)
    execute '!' . cmdline
    call s:cd(cwd)
  endif

  return ''
endfunction

""
" @private
" Hack for testing script-local functions.
function! laravel#homestead#sid()
  nnoremap <SID> <SID>
  return maparg('<SID>', 'n')
endfunction

" vim: fdm=marker:sw=2:sts=2:et
