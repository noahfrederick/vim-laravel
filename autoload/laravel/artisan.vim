" autoload/laravel/artisan.vim - Laravel Artisan support for Vim
" Maintainer: Noah Frederick

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
" Implement the one-argument version of uniq() for older Vims.
function! s:uniq(list) abort
  if exists('*uniq')
    return uniq(a:list)
  endif

  let i = 0
  let last = ''

  while i < len(a:list)
    let str = string(a:list[i])
    if str ==# last && i > 0
      call remove(a:list, i)
    else
      let last = str
      let i += 1
    endif
  endwhile

  return a:list
endfunction

""
" Get output from Artisan with {args} in project's root directory.
function! s:artisan_exec(args) abort
  try
    let cwd = s:cd(laravel#app().path())
    let result = systemlist(join([laravel#app().makeprg()] + a:args))
  finally
    call s:cd(cwd)
  endtry

  return result
endfunction

""
" Get Dict of artisan subcommands.
function! s:artisan_commands() abort
  if laravel#app().cache.needs('artisan_commands')
    let lines = s:artisan_exec(['list', '--raw'])

    if v:shell_error != 0
      return []
    endif

    call map(lines, "matchstr(v:val, '^.\\{-}\\ze\\s')")
    call filter(lines, 'v:val != ""')

    call laravel#app().cache.set('artisan_commands', lines)
  endif

  return laravel#app().cache.get('artisan_commands')
endfunction

""
" The :Artisan command.
function! laravel#artisan#exec(...) abort
  let args = copy(a:000)
  let bang = remove(args, 0)

  " if exists(':terminal')
  "   tabedit %
  "   execute 'lcd' fnameescape(laravel#app().path())
  "   execute 'terminal' laravel#app().makeprg() join(args)
  " else
    let cwd = s:cd(laravel#app().path())
    execute '!' . laravel#app().makeprg() join(args)
    call s:cd(cwd)
  " endif

  return ''
endfunction

""
" @private
" Completion for the :Artisan command.
function! laravel#artisan#complete(A, L, P) abort
  let commands = copy(s:artisan_commands())

  call remove(commands, index(commands, 'help'))
  let subcommand = matchstr(a:L, '\<\(' . join(commands, '\|') . '\)\>')
  let help = matchstr(a:L, '\<help\>')

  let candidates = s:artisan_flags['_global']

  if empty(subcommand)
    let candidates = candidates + commands + ['help']
  elseif has_key(s:artisan_flags, subcommand)
    let candidates = candidates + s:artisan_flags[subcommand]
  endif

  return s:filter_completions(candidates, a:A)
endfunction

""
" Sort and filter completion {candidates} based on the current argument {A}.
" Adapted from bundler.vim.
function! s:filter_completions(candidates, A) abort
  let candidates = copy(a:candidates)
  if len(candidates) == 0
    return []
  endif
  call sort(candidates)
  call s:uniq(candidates)

  let commands = filter(copy(candidates), "v:val[0] !=# '-'")
  let flags = filter(copy(candidates), "v:val[0] ==# '-'")

  let candidates = commands + flags

  let filtered = filter(copy(candidates), 'v:val[0:strlen(a:A)-1] ==# a:A')
  if !empty(filtered) | return filtered | endif

  let regex = substitute(a:A, '[^/:]', '[&].*', 'g')
  let filtered = filter(copy(candidates), 'v:val =~# "^".regex')
  if !empty(filtered) | return filtered | endif

  let filtered = filter(copy(candidates), '"/".v:val =~# "[/:]".regex')
  if !empty(filtered) | return filtered | endif

  let regex = substitute(a:A, '.', '[&].*', 'g')
  let filtered = filter(copy(candidates),'"/".v:val =~# regex')
  return filtered
endfunction

" Unlike subcommands, artisan does not list switches/flags in a friendly
" format, so we hard-code them.
let s:artisan_flags = {
      \   '_global': [
      \     '--help',
      \     '-h',
      \     '--quiet',
      \     '-q',
      \     '--verbose',
      \     '-v',
      \     '-vv',
      \     '-vvv',
      \     '--version',
      \     '-V',
      \     '--ansi',
      \     '--no-ansi',
      \     '--no-interaction',
      \     '-n',
      \     '--env=',
      \   ],
      \   'db:seed': [
      \     '--class=',
      \     '--database=',
      \     '--force',
      \   ],
      \   'help': [
      \     '--format=',
      \     '--raw',
      \   ],
      \   'key:generate': [
      \     '--show',
      \   ],
      \   'list': [
      \     '--format=',
      \     '--raw',
      \   ],
      \   'make:auth': [
      \     '--views',
      \   ],
      \   'make:console': [
      \     '--command=',
      \   ],
      \   'make:controller': [
      \     '--resource',
      \   ],
      \   'make:job': [
      \     '--sync',
      \   ],
      \   'make:listener': [
      \     '--event=',
      \     '--queued',
      \   ],
      \   'make:migration': [
      \     '--create=',
      \     '--table=',
      \     '--path=',
      \   ],
      \   'make:model': [
      \     '--migration',
      \     '-m',
      \   ],
      \   'migrate': [
      \     '--database=',
      \     '--force',
      \     '--path=',
      \     '--pretend',
      \     '--seed',
      \     '--step',
      \   ],
      \   'migrate:install': [
      \     '--database=',
      \   ],
      \   'migrate:refresh': [
      \     '--database=',
      \     '--force',
      \     '--path=',
      \     '--seed',
      \     '--seeder=',
      \   ],
      \   'migrate:reset': [
      \     '--database=',
      \     '--force',
      \     '--pretend',
      \   ],
      \   'migrate:rollback': [
      \     '--database=',
      \     '--force',
      \     '--pretend',
      \   ],
      \   'migrate:status': [
      \     '--database=',
      \     '--path=',
      \   ],
      \   'optimize': [
      \     '--force',
      \     '--psr',
      \   ],
      \   'queue:listen': [
      \     '--queue=',
      \     '--delay=',
      \     '--memory=',
      \     '--timeout=',
      \     '--sleep=',
      \     '--tries=',
      \   ],
      \   'queue:work': [
      \     '--queue=',
      \     '--daemon',
      \     '--delay=',
      \     '--force',
      \     '--memory=',
      \     '--sleep=',
      \     '--tries=',
      \   ],
      \   'route:list': [
      \     '--method=',
      \     '--name=',
      \     '--path=',
      \     '--reverse',
      \     '-r',
      \     '--sort=',
      \   ],
      \   'serve': [
      \     '--host=',
      \     '--port=',
      \   ],
      \   'vendor:publish': [
      \     '--force',
      \     '--provider=',
      \     '--tag=',
      \   ],
      \ }

""
" @private
" Hack for testing script-local functions.
function! laravel#artisan#sid()
  nnoremap <SID> <SID>
  return maparg('<SID>', 'n')
endfunction

" vim: fdm=marker:sw=2:sts=2:et
