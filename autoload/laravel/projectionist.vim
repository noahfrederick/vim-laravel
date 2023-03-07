" autoload/laravel/projectionist.vim - Projections for Laravel projects
" Maintainer: Noah Frederick

if !exists('g:projectionist_transformations')
  let g:projectionist_transformations = {}
endif

function! g:projectionist_transformations.namespace(input, o) abort
  return laravel#app().namespace(expand('%'))
endfunction

function! laravel#projectionist#append() abort
  let templates = {
        \ 'generic': [
        \   '<?php',
        \ ],
        \ 'array': [
        \   '<?php',
        \   '',
        \   'return [',
        \   '    //',
        \   '];',
        \ ],
        \ 'class': [
        \   '<?php',
        \   '',
        \   'namespace {namespace};',
        \   '',
        \   'class {basename}',
        \   '{open}',
        \   '    //',
        \   '{close}',
        \ ],
        \ 'trait': [
        \   '<?php',
        \   '',
        \   'namespace {namespace};',
        \   '',
        \   'trait {basename}',
        \   '{open}',
        \   '    //',
        \   '{close}',
        \ ],
        \ }

  let projections = {
        \ '*': {
        \   'start': [laravel#app().makeprg(), 'serve'],
        \   'console': [laravel#app().makeprg(), 'tinker'],
        \   'framework': 'laravel',
        \ },
        \ '*.php': {
        \   'template': templates.generic,
        \ },
        \ 'bootstrap/*.php': {
        \   'type': 'bootstrap',
        \ },
        \ 'bootstrap/app.php': {
        \   'type': 'bootstrap',
        \ },
        \ 'config/*.php': {
        \   'type': 'config',
        \   'template': templates.array,
        \ },
        \ 'config/app.php': {
        \   'type': 'config',
        \ },
        \ 'app/*.php': {
        \   'type': 'lib',
        \   'template': templates.class,
        \ },
        \ 'app/Broadcasting/*.php': {
        \   'type': 'channel',
        \   'related': 'app/Providers/BroadcastServiceProvider.php',
        \ },
        \ 'app/Casts/*.php': {
        \   'type': 'cast',
        \ },
        \ 'app/View/Components/*.php': {
        \   'type': 'component',
        \ },
        \ 'app/Http/Controllers/*.php': {
        \   'type': 'controller',
        \ },
        \ 'app/Http/Controllers/Controller.php': {
        \   'type': 'controller',
        \ },
        \ 'app/Mail/*.php': {
        \   'type': 'mail',
        \ },
        \ 'app/Http/Middleware/*.php': {
        \   'type': 'middleware',
        \ },
        \ 'app/Http/Kernel.php': {
        \   'type': 'middleware',
        \ },
        \ 'app/Http/Requests/*.php': {
        \   'type': 'request',
        \ },
        \ 'app/Http/Resources/*.php': {
        \   'type': 'resource',
        \ },
        \ 'app/Rules/*.php': {
        \   'type': 'rule',
        \ },
        \ 'app/Events/*.php': {
        \   'type': 'event',
        \   'alternate': 'app/Listeners/{}.php',
        \   'related': 'app/Providers/EventServiceProvider.php',
        \ },
        \ 'app/Events/Event.php': {
        \   'type': 'event',
        \ },
        \ 'app/Exceptions/*.php': {
        \   'type': 'exception',
        \ },
        \ 'app/Exceptions/Handler.php': {
        \   'type': 'exception',
        \ },
        \ 'app/Notifications/*.php': {
        \   'type': 'notification',
        \ },
        \ 'app/Observers/*.php': {
        \   'type': 'observer',
        \ },
        \ 'app/Policies/*.php': {
        \   'type': 'policy',
        \   'alternate': 'app/Providers/AuthServiceProvider.php',
        \ },
        \ 'app/Providers/*.php': {
        \   'type': 'provider',
        \ },
        \ 'database/*.php': {
        \   'template': templates.class,
        \ },
        \ 'database/factories/*.php': {
        \   'type': 'factory',
        \ },
        \ 'database/factories/ModelFactory.php': {
        \   'type': 'factory',
        \ },
        \ 'database/migrations/*.php': {
        \   'type': 'migration',
        \   'template': templates.generic,
        \ },
        \ 'tests/*.php': {
        \   'type': 'test',
        \   'template': templates.class,
        \ },
        \ 'tests/TestCase.php': {
        \   'type': 'test',
        \   'alternate': 'phpunit.xml',
        \ },
        \ 'phpunit.xml': {
        \   'alternate': 'tests/TestCase.php',
        \ },
        \ 'resources/lang/*.php': {
        \   'type': 'language',
        \   'template': templates.array,
        \ },
        \ 'resources/assets/*': {
        \   'type': 'asset',
        \ },
        \ 'README.md': {
        \   'type': 'doc',
        \ }}

  if laravel#app().has('blade')
    let projections['resources/views/*.blade.php'] = {
          \   'type': 'view',
          \ }
  else " Assume plain PHP templates
    let projections['resources/views/*.php'] = {
          \   'type': 'view',
          \ }
  endif

  if laravel#app().has('dotenv')
    let projections['.env'] = {
          \   'type': 'env',
          \   'alternate': '.env.example',
          \ }

    let projections['.env.example'] = {
          \   'alternate': '.env',
          \ }
  endif

  if laravel#app().has('commands')
    let projections['app/Commands/*.php'] = {
          \   'type': 'command',
          \ }

    let projections['app/Console/Commands/*.php'] = {
          \   'type': 'console',
          \ }

    let projections['app/Console/Kernel.php'] = {
          \   'type': 'console',
          \ }
  else
    let projections['app/Jobs/*.php'] = {
          \   'type': 'job',
          \ }

    let projections['app/Jobs/Job.php'] = {
          \   'type': 'job',
          \ }

    let projections['app/Console/Commands/*.php'] = {
          \   'type': 'command',
          \ }

    let projections['app/Console/Kernel.php'] = {
          \   'type': 'command',
          \ }
  endif

  if laravel#app().has('handlers')
    let projections['app/Handlers/*.php'] = {
          \   'type': 'handler',
          \   'alternate': 'app/Events/{}.php',
          \ }
  else
    let projections['app/Listeners/*.php'] = {
          \   'type': 'listener',
          \   'alternate': 'app/Events/{}.php',
          \ }
  endif

  if laravel#app().has('models')
    let projections['app/Models/*.php'] = {
          \   'type': 'model',
          \ }
  endif

  " In Laravel 8, the seeds/ directory was renamed to seeders/.
  if laravel#app().has('database/seeds/')
    let projections['database/seeds/*.php'] = {
          \   'type': 'seeder',
          \ }
    let projections['database/seeds/DatabaseSeeder.php'] = {
          \   'type': 'seeder',
          \ }
  else
    let projections['database/seeders/*.php'] = {
          \   'type': 'seeder',
          \ }
    let projections['database/seeders/DatabaseSeeder.php'] = {
          \   'type': 'seeder',
          \ }
  endif

  if laravel#app().has('routes')
    let projections['routes/*.php'] = {
          \   'type': 'routes',
          \   'alternate': 'app/Http/Kernel.php',
          \   'related': 'app/Providers/RouteServiceProvider.php',
          \ }
  else
    let projections['app/Http/routes.php'] = {
          \   'type': 'routes',
          \   'alternate': 'app/Http/Kernel.php',
          \   'related': 'app/Providers/RouteServiceProvider.php',
          \ }
  endif

  if laravel#app().has('scopes')
    let projections['app/Scopes/*.php'] = {
          \   'type': 'scope',
          \   'template': [
          \     '<?php',
          \     '',
          \     'namespace {namespace};',
          \     '',
          \     'use Illuminate\Database\Eloquent\Scope;',
          \     'use Illuminate\Database\Eloquent\Model;',
          \     'use Illuminate\Database\Eloquent\Builder;',
          \     '',
          \     'class {basename} implements Scope',
          \     '{open}',
          \     '    /**',
          \     '     * Apply the scope to a given Eloquent query builder.',
          \     '     *',
          \     '     * @param  \Illuminate\Database\Eloquent\Builder  $builder',
          \     '     * @param  \Illuminate\Database\Eloquent\Model  $model',
          \     '     * @return void',
          \     '     */',
          \     '    public function apply(Builder $builder, Model $model)',
          \     '    {open}',
          \     '        //',
          \     '    {close}',
          \     '{close}',
          \   ],
          \ }
  endif

  if laravel#app().has('traits')
    let projections['app/Traits/*.php'] = {
          \   'type': 'trait',
          \   'template': templates.trait,
          \ }
  endif

  return projectionist#append(b:laravel_root, projections)
endfunction

" vim: fdm=marker:sw=2:sts=2:et
