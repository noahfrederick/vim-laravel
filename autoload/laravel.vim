" autoload/laravel.vim - Laravel autoloads
" Maintainer: Noah Frederick

""
" Throw error with {msg}.
function! s:throw(msg) abort
  let v:errmsg = 'laravel: ' . a:msg
  throw v:errmsg
endfunction

""
" Get Funcref from script-local function {name}.
function! s:function(name) abort
  return function(substitute(a:name, '^s:', matchstr(expand('<sfile>'), '<SNR>\d\+_'), ''))
endfunction

""
" Add {method_names} to prototype {namespace} Dict. Follows the same pattern
" as rake.vim.
function! s:add_methods(namespace, method_names) abort
  for name in a:method_names
    let s:{a:namespace}_prototype[name] = s:function('s:' . a:namespace . '_' . name)
  endfor
endfunction

let s:app_prototype = {}
let s:apps = {}

""
" @private
" Get the app object belonging to the current app root, or that
" of [root]. Initializes the app if not initialized.
function! laravel#app(...) abort
  let root = get(a:000, 0, exists('b:laravel_root') && b:laravel_root !=# '' ? b:laravel_root : '')

  if empty(root)
    return {}
  endif

  if !has_key(s:apps, root)
    let s:apps[root] = deepcopy(s:app_prototype)
    let s:apps[root]._root = root
  endif

  return get(s:apps, root, {})
endfunction

""
" Get the app object belonging to the current app root, or that
" of [root]. Throws an error if not in a Laravel app.
function! s:app(...) abort
  let app = call('laravel#app', a:000)

  if !empty(app)
    return app
  endif

  call s:throw('not a Laravel app: ' . expand('%:p'))
endfunction

""
" Get absolute path to app root, optionally with [path] appended.
function! s:app_path(...) dict abort
  return join([self._root] + a:000, '/')
endfunction

""
" Check whether path exists in project.
function! s:app_has_path(path) dict abort
  let path = a:path[0] ==# '/' ? a:path : self.path(a:path)
  return getftime(path) != -1
endfunction

""
" Check whether directory exists in project.
function! s:app_has_dir(dir) dict abort
  let path = a:dir[0] ==# '/' ? a:dir : self.path(a:dir)
  return isdirectory(path)
endfunction

""
" Check whether file is readable in project.
function! s:app_has_file(file) dict abort
  let path = a:file[0] ==# '/' ? a:file : self.path(a:file)
  return filereadable(path)
endfunction

""
" Get absolute path to source directory, optionally with [path] appended.
function! s:app_src_path(...) dict abort
  return join([self._root, 'app'] + a:000, '/')
endfunction

""
" Get absolute path to config directory, optionally with [path] appended.
function! s:app_config_path(...) dict abort
  return join([self._root, 'config'] + a:000, '/')
endfunction

""
" Get absolute path to migrations directory, optionally with [path] appended.
function! s:app_migrations_path(...) dict abort
  return join([self._root, 'database/migrations'] + a:000, '/')
endfunction

""
" Translate migration name to path.
function! s:app_find_migration(slug) dict abort
  let candidates = glob(self.migrations_path('*_'.a:slug.'.php'), 1, 1)
  return (empty(candidates) ? '' : remove(candidates, -1))
endfunction

""
" Expand migration slug to full name with timestamp.
function! s:app_expand_migration(slug) dict abort
  return fnamemodify(self.find_migration(a:slug), ':t:r')
endfunction

call s:add_methods('app', ['has_dir', 'has_file', 'has_path'])
call s:add_methods('app', ['path', 'src_path', 'config_path', 'migrations_path', 'find_migration', 'expand_migration'])

""
" Detect app's namespace
function! s:app_detect_namespace() abort dict
  try
    let paths = composer#query('autoload.psr-4')

    for [namespace, path] in items(paths)
      if self.has_path(path)
        return namespace[0:-2]
      endif
    endfor
  catch /^Vim\%((\a\+)\)\=:E117/
    " Fall through when composer.vim isn't available
  endtry

  return 'App'
endfunction

""
" Get app's namespace or namespace for file at [path]
function! s:app_namespace(...) abort dict
  if self.cache.needs('namespace')
    call self.cache.set('namespace', self.detect_namespace())
  endif

  let ns = [self.cache.get('namespace')]

  if a:0 == 1
    let path = substitute(fnamemodify(a:1, ':p'), '\V\^' . self.src_path(), '', '')
    let ns += split(path, '/')[0:-2]
  endif

  return join(ns, '\')
endfunction

""
" Detect existence of {feature} in the current app.
function! s:app_has(feature) abort dict
  if a:feature =~# '\v^(laravel|lumen)'
    return s:has_framework(a:feature)
  endif

  return s:has_feature_by_path(self, a:feature)
endfunction

function! s:has_framework(feature)
  if a:feature =~# '^laravel'
    let package = 'laravel/framework'
    let constraint = substitute(a:feature, '^laravel', '', '')
  elseif a:feature =~# '^lumen'
    let package = 'laravel/lumen-framework'
    let constraint = substitute(a:feature, '^lumen', '', '')
  else
    return 0
  endif

  try
    let ver = composer#query('require.' . package)
  catch /^Vim\%((\a\+)\)\=:E117/
    return 0
  endtry

  let constraint = '^[^0-9]*' . escape(constraint, '.')

  return !empty(ver) && match(ver, constraint) >= 0
endfunction

function! s:has_feature_by_path(app, feature)
  let map = {
        \ 'artisan': 'artisan',
        \ 'commands': 'app/Commands/',
        \ 'dotenv': '.env|.env.example',
        \ 'gulp': 'gulpfile.js',
        \ 'handlers': 'app/Handlers/',
        \ 'jobs': 'app/Jobs/',
        \ 'listeners': 'app/Listeners/',
        \ 'mail': 'app/Mail/',
        \ 'models': 'app/Models/',
        \ 'namespaced-tests': 'tests/Feature/|tests/Unit/',
        \ 'policies': 'app/Policies/',
        \ 'scopes': 'app/Scopes/',
        \ 'traits': 'app/Traits/',
        \ }

  let path = get(map, a:feature, a:feature.'/')

  return !empty(filter(split(path, '|'), 'a:app.has_path(v:val)'))
endfunction

call s:add_methods('app', ['detect_namespace', 'namespace', 'has'])

""
" Read first [n] lines of file at {path}.
" Adapted from rails.vim.
function! s:readfile(path, ...)
  let nr = bufnr('^' . a:path . '$')

  if nr < 0 && exists('+shellslash') && ! &shellslash
    let nr = bufnr('^' . substitute(a:path, '/', '\\', 'g') . '$')
  endif

  if bufloaded(nr)
    return getbufline(nr, 1, a:0 ? a:1 : '$')
  elseif !filereadable(a:path)
    return []
  elseif a:0
    return readfile(a:path, '', a:1)
  else
    return readfile(a:path)
  endif
endfunction

""
" Get dict of registered facades in the form
"
"   { 'App': 'Illuminate\Support\Facades\App', ... }
function! s:app_facades() abort dict
  if self.cache.needs('facades')
    let facades = {}

    if ! self.has_file(self.config_path('app.php'))
      return facades
    endif

    let lines = s:readfile(self.config_path('app.php'))

    let start_pat = "^\\s\\+'aliases'\\s\\+=>\\s\\+["
    let end_pat = '^\s\+],'
    let item_pat = "^\\s\\+'\\(\\w\\+\\)'\\s\\+=>\\s\\+\\([A-Za-z_\\\\]\\+\\)::class,"
    let start_seen = 0

    for line in lines
      if start_seen && line =~# end_pat
        break
      elseif line =~# start_pat
        let start_seen = 1
      elseif start_seen && line =~# item_pat
        let [class, ns] = matchlist(line, item_pat)[1:2]
        let facades[class] = ns
      else
        continue
      endif
    endfor

    call self.cache.set('facades', facades)
  endif

  return self.cache.get('facades')
endfunction

call s:add_methods('app', ['facades'])

function! s:app_makeprg() abort dict
  return 'php artisan'
endfunction

call s:add_methods('app', ['makeprg'])

let s:cache_prototype = {'_dict': {}}

function! s:cache_clear(...) dict abort
  if a:0 == 0
    let self._dict = {}
  elseif has_key(self, '_dict') && has_key(self._dict, a:1)
    unlet! self._dict[a:1]
  endif
endfunction

function! laravel#cache_clear(...) abort
  if exists('b:laravel_root')
    return call(laravel#app().cache.clear, a:000, laravel#app().cache)
  endif
endfunction

function! s:cache_get(...) dict abort
  if a:0 == 0
    return self._dict
  else
    return self._dict[a:1]
  endif
endfunction

function! s:cache_set(key, value) dict abort
  let self._dict[a:key] = a:value
endfunction

function! s:cache_has(key) dict abort
  return has_key(self._dict, a:key)
endfunction

function! s:cache_needs(key) dict abort
  return !has_key(self._dict, a:key)
endfunction

call s:add_methods('cache', ['clear', 'get', 'set', 'has', 'needs'])

let s:app_prototype.cache = s:cache_prototype

""
" Get namespace of buffer's file
function! s:buffer_namespace() abort dict
  let path = self.path
  let ns = s:app.namespace()

  if empty(path)
    return ns
  endif

  let path = fnamemodify(path, ':p:h')
  let path = substitute(path, '\V\^' . s:app.src_path(), '')
  return join([ns] + split(path, '/'), '\')
endfunction

function! s:buffer_type() abort dict
endfunction

function! s:buffer_is_type(types) abort dict
  let types = type(a:types) == type([]) ? a:types : [a:types]
  return (index(types, self.type()) != -1)
endfunction

""
" @private
" Apply extensions to the PHP syntax definitions
function! laravel#buffer_syntax() abort
endfunction

""
" @private
" Set up Laravel buffers
function! laravel#buffer_setup() abort
  call laravel#buffer_commands()
  call laravel#buffer_mappings()

  silent doautocmd User Laravel
endfunction

""
" @private
" Set up commands for Laravel buffers
function! laravel#buffer_commands() abort
  ""
  " @command Artisan[!] [arguments]
  " Invoke Artisan with [arguments] (with intelligent completion).
  command! -buffer -bang -bar -nargs=* -complete=customlist,laravel#artisan#complete
        \ Artisan execute laravel#artisan#exec(<q-bang>, <f-args>)
endfunction

""
" @private
" Set up mappings for Laravel buffers
function! laravel#buffer_mappings() abort
  if &filetype =~# 'php'
    if hasmapto('<Plug>(laravel-goto-php)') | return 1 | endif
    nmap <buffer> gf <Plug>(laravel-goto-php)
  elseif &filetype =~# 'blade'
    if hasmapto('<Plug>(laravel-goto-blade)') | return 1 | endif
    nmap <buffer> gf <Plug>(laravel-goto-blade)
  else
    return 2
  endif
endfunction

" Abbrevs
"
"    as(  asset
"    sa(  secure_asset
"     u(  url
"    au(  auth
"    ba(  back
"    bc(  bcrypt
"    co(  config
"    cf(  csrf_field
"    ct(  csrf_token
"    ev(  event
"    fa(  factory
"    mf(  method_field
"   red(  redirect
"   req(  request
"   res(  response
"    se(  session
"  sess(  session
"   val(  value
"     v(  view
"     w(  with
"    ro(  route
"   Art:: Artisan
"    Au:: Auth
"    Bl:: Blade
"    Ca:: Cache
"    Co:: Config
"   Coo:: Cookie
"    Cr:: Crypt
"    Ev:: Event
"     F:: File
"    Ga:: Gate
"    Ha:: Hash
"    In:: Input
"    La:: Lang
"  Pass:: Password
"     Q:: Queue
"   Red:: Redirect
"   Res:: Response
"   Req:: Request
"    Se:: Session
"  Sess:: Session
"   Sto:: Storage
"     U:: URL
"   Val:: Validator
"     V:: View

" vim: fdm=marker:sw=2:sts=2:et
