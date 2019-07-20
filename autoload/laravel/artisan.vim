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
    call laravel#throw('JSON cannot be parsed')
  catch /^invalid JSON/
    call laravel#throw('JSON cannot be parsed')
  catch /^Vim\%((\a\+)\)\=:E117/
    call laravel#throw('projectionist is not available')
  endtry
  return {}
endfunction

""
" Get output from Artisan with {args} in project's root directory.
function! laravel#artisan#capture(app, args) abort
  try
    let cwd = s:cd(a:app.path())
    let result = systemlist(a:app.makeprg(a:args))
  finally
    call s:cd(cwd)
  endtry

  return result
endfunction

""
" Get Dict from artisan list --format=json.
function! s:artisan_json(app) abort
  if a:app.cache.needs('artisan_json')
    let lines = laravel#artisan#capture(a:app, ['list', '--format=json'])

    let json = {}

    if v:shell_error == 0
      try
        let json = s:json_decode(lines)
      endtry
    endif

    call a:app.cache.set('artisan_json', json)
  endif

  return a:app.cache.get('artisan_json')
endfunction

""
" Get Dict of artisan subcommands and their descriptions.
function! laravel#artisan#commands(app) abort
  if a:app.cache.needs('artisan_commands')
    let definitions = get(s:artisan_json(a:app), 'commands', [])
    let commands = {}

    if !empty(definitions)
      for command in definitions
        let commands[command.name] = command.description
      endfor
    endif

    call a:app.cache.set('artisan_commands', commands)
  endif

  return deepcopy(a:app.cache.get('artisan_commands'))
endfunction

""
" Get Dict of artisan subcommands and their options.
function! laravel#artisan#command_options(app) abort
  if a:app.cache.needs('artisan_command_options')
    let definitions = get(s:artisan_json(a:app), 'commands', [])
    let commands = {}

    if !empty(definitions)
      for command in definitions
        let options = []

        for [name, option] in items(get(command.definition, 'options', {}))
          if option.accept_value
            call add(options, option.name . '=')
          else
            call add(options, option.name)
          endif

          if !empty(option.shortcut)
            call add(options, option.shortcut)
          endif
        endfor

        let commands[command.name] = options
      endfor
    endif

    call a:app.cache.set('artisan_command_options', commands)
  endif

  return deepcopy(a:app.cache.get('artisan_command_options'))
endfunction

function! s:artisan_commands() abort
  return laravel#artisan#command_options(laravel#app())
endfunction

""
" Get list of artisan subcommand flags.
function! s:artisan_flags(subcommand) abort
  return get(s:artisan_commands(), a:subcommand, s:artisan_global_flags)
endfunction

let s:artisan_global_flags = [
      \   '--help',
      \   '-h',
      \   '--quiet',
      \   '-q',
      \   '--verbose',
      \   '-v',
      \   '-vv',
      \   '-vvv',
      \   '--version',
      \   '-V',
      \   '--ansi',
      \   '--no-ansi',
      \   '--no-interaction',
      \   '-n',
      \   '--env=',
      \ ]

""
" The :Artisan command.
function! laravel#artisan#exec(...) abort
  let args = copy(a:000)
  let bang = remove(args, 0)

  let cwd = s:cd(laravel#app().path())
  execute '!' . laravel#app().makeprg(args)
  call s:cd(cwd)

  call s:artisan_doautocmd(args, bang, v:shell_error)
  return ''
endfunction

""
" Execute Artisan autocommand with event object.
function! s:artisan_doautocmd(args, bang, status) abort
  let g:artisan = {
        \   'args': a:args,
        \   'bang': a:bang,
        \   'status': a:status,
        \ }
  let g:artisan.flags = filter(copy(a:args), 'v:val =~# "^-"')
  let g:artisan.rest = filter(copy(a:args), 'v:val !~# "^-"')
  if empty(g:artisan.rest)
    let parts = ['']
  else
    let parts = split(remove(g:artisan.rest, 0), ':')
  endif
  let g:artisan.namespace = len(parts) > 1 ? parts[0] : ''
  let g:artisan.name = len(parts) > 1 ? parts[1] : parts[0]

  silent doautocmd User Artisan
endfunction

augroup laravel_artisan
  autocmd!
  if exists('g:loaded_projectionist')
    autocmd User Artisan nested
          \ if g:artisan.status == 0 && g:artisan.namespace ==# 'make' |
          \   execute s:artisan_edit(g:artisan) |
          \ endif
  endif
augroup END

""
" Edit the file generated by an Artisan command.
function! s:artisan_edit(command) abort
  if a:command.name ==# 'auth'
    return ''
  elseif a:command.name ==# 'console'
    let type = 'command'
  elseif a:command.name ==# 'model'
    let type = 'lib'
  else
    let type = a:command.name
  endif

  if !exists(':E' . type)
    call laravel#warn('Cannot edit generated ' . type . ' file')
    return ''
  endif

  let classname = remove(a:command.rest, 0)
  let namespace = ''

  if a:command.name ==# 'migration'
    let classname = laravel#app().expand_migration(classname)
  elseif a:command.name ==# 'test' && laravel#app().has('namespaced-tests')
    let namespace = index(a:command.args, '--unit') != -1 ? 'Unit/' : 'Feature/'
  endif

  return 'E' . type . a:command.bang . ' ' . namespace . classname
endfunction

""
" @private
" Completion for the :Artisan command.
function! laravel#artisan#complete(A, L, P) abort
  let commands = keys(s:artisan_commands())

  silent! call remove(commands, index(commands, 'help'))
  let subcommand = matchstr(a:L, '\<\(' . join(commands, '\|') . '\)\>')

  if empty(subcommand)
    let candidates = commands + ['help'] + s:artisan_flags('_')
  else
    let candidates = s:artisan_flags(subcommand)
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

""
" @private
" Hack for testing script-local functions.
function! laravel#artisan#sid()
  nnoremap <SID> <SID>
  return maparg('<SID>', 'n')
endfunction

" vim: fdm=marker:sw=2:sts=2:et
