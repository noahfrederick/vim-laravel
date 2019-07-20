" autoload/laravel/completion.vim - Completion sources
" Maintainer: Noah Frederick

function! laravel#completion#cm_routes(ctx) abort
  if exists('b:laravel_root')
    call s:cm_complete(laravel#app().routes(), a:ctx)
  endif
endfunction

function! laravel#completion#cm_views(ctx) abort
  if exists('b:laravel_root')
    call s:cm_complete(laravel#app().templates(), a:ctx)
  endif
endfunction

function! s:cm_complete(candidates, ctx) abort
  let matches = map(keys(a:candidates), '{"word": v:val, "info": a:candidates[v:val]}')
  call ncm2#complete(a:ctx, a:ctx['startccol'], matches)
endfunction

" vim: fdm=marker:sw=2:sts=2:et
