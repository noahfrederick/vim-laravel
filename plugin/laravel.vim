" plugin/laravel.vim - Detect a Laravel/Lumen project
" Maintainer:  Noah Frederick (https://noahfrederick.com)

""
" @section Introduction, intro
" @stylized Laravel.vim
" @plugin(stylized) provides conveniences for working with Laravel/Lumen
" projects. Some features include:
"
" * The |:Artisan| command wraps artisan with intelligent completion.
" * Includes projections for projectionist.vim.
" * Use |:Console| to fire up a REPL (artisan tinker).
"
" This plug-in is only available if 'compatible' is not set.

""
" @section About, about
" @plugin(stylized) is distributed under the same terms as Vim itself (see
" |license|)
"
" You can find the latest version of this plug-in on GitHub:
" https://github.com/noahfrederick/vim-@plugin(name)
"
" Please report issues on GitHub as well:
" https://github.com/noahfrederick/vim-@plugin(name)/issues

if (exists('g:loaded_laravel') && g:loaded_laravel) || &cp
  finish
endif
let g:loaded_laravel = 1

" Detection {{{

""
" Determine whether the current or supplied [path] belongs to a Laravel project
function! s:laravel_detect(...) abort
  if exists('b:laravel_root')
    return 1
  endif

  let fn = fnamemodify(a:0 ? a:1 : expand('%'), ':p')

  if !isdirectory(fn)
    let fn = fnamemodify(fn, ':h')
  endif

  let bootstrap = findfile('bootstrap/app.php', escape(fn, ', ') . ';')
  let artisan = findfile('artisan', escape(fn, ', ') . ';')

  if !empty(bootstrap) && !empty(artisan)
    let b:laravel_root = fnamemodify(artisan, ':p:h')
    return 1
  endif
endfunction

" }}}
" Initialization {{{

augroup laravel_detect
  autocmd!
  " Project detection
  autocmd BufNewFile,BufReadPost *
        \ if s:laravel_detect(expand("<afile>:p")) && empty(&filetype) |
        \   call laravel#buffer_setup() |
        \ endif
  autocmd VimEnter *
        \ if empty(expand("<amatch>")) && s:laravel_detect(getcwd()) |
        \   call laravel#buffer_setup() |
        \ endif
  autocmd FileType * if s:laravel_detect() | call laravel#buffer_setup() | endif
  autocmd BufNewFile,BufReadPost */storage/logs/*.log if s:laravel_detect() | call laravel#log_buffer_setup() | endif

  " File-type-specific setup
  autocmd Syntax php
        \ if s:laravel_detect() | call laravel#buffer_syntax() | endif
augroup END

nnoremap <Plug>(laravel-goto-php) :<C-u>execute laravel#goto#filetype_php()<CR>
nnoremap <Plug>(laravel-goto-blade) :<C-u>execute laravel#goto#filetype_blade()<CR>

" }}}
" Projections {{{

" Ensure that projectionist gets loaded first
if !exists('g:loaded_projectionist')
  runtime! plugin/projectionist.vim
endif

augroup laravel_projections
  autocmd!
  autocmd User ProjectionistDetect
        \ if s:laravel_detect(get(g:, 'projectionist_file', '')) |
        \   call laravel#projectionist#append() |
        \ endif
augroup END

" }}}
" Completion {{{

augroup laravel_completion
  autocmd!
  " Set up nvim-completion-manager sources
  " :help NCM-source-examples
  autocmd User CmSetup call cm#register_source({'name' : 'Laravel Route',
        \ 'abbreviation': 'Route',
        \ 'priority': 9,
        \ 'scoping': 1,
        \ 'scopes': ['php', 'blade'],
        \ 'word_pattern': '[A-Za-z0-9_.:-]+',
        \ 'cm_refresh_patterns': ['\broute\([''"]'],
        \ 'cm_refresh': 'laravel#completion#cm_routes',
        \ })
  autocmd User CmSetup call cm#register_source({'name' : 'Laravel View',
        \ 'abbreviation': 'View',
        \ 'priority': 9,
        \ 'scoping': 1,
        \ 'scopes': ['php', 'blade'],
        \ 'word_pattern': '[A-Za-z0-9_.:-]+',
        \ 'cm_refresh_patterns': ['\bview\([''"]', '@(component|extends|include)\([''"]'],
        \ 'cm_refresh': 'laravel#completion#cm_views',
        \ })

  " Set up ncm2 sources
  " :help ncm2#register_source-example
  autocmd User Ncm2Plugin call ncm2#register_source({
        \ 'name': 'Laravel Route',
        \ 'priority': 9,
        \ 'subscope_enable': 1,
        \ 'scope': ['php', 'blade'],
        \ 'mark': 'Route',
        \ 'word_pattern': '[A-Za-z0-9_.:-]+',
        \ 'complete_length': -1,
        \ 'complete_pattern': ['\broute\([''"]'],
        \ 'on_complete': 'laravel#completion#ncm2_routes',
        \ })
  autocmd User Ncm2Plugin call ncm2#register_source({
        \ 'name': 'Laravel View',
        \ 'priority': 9,
        \ 'subscope_enable': 1,
        \ 'scope': ['php', 'blade'],
        \ 'mark': 'View',
        \ 'word_pattern': '[A-Za-z0-9_.:-]+',
        \ 'complete_length': -1,
        \ 'complete_pattern': ['\bview\([''"]', '@(component|extends|include)\([''"]'],
        \ 'on_complete': 'laravel#completion#ncm2_views',
        \ })
augroup END

" }}}
" vim: fdm=marker:sw=2:sts=2:et
