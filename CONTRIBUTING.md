# Contributing

## Testing

Tests are written for [vspec][vspec], which can be installed via
[vim-flavor][vim-flavor]:

	bundle install
	bundle exec vim-flavor install

The test suite can then be run via the rake task:

	bundle exec rake test

## Documentation

The documentation in `doc/` is generated from the plug-in source code via
[vimdoc][vimdoc]. Do not edit `doc/<plugin>.txt` directly. Refer to the
existing inline documentation as a guide for documenting new code.

The help doc can be rebuilt by running:

	bundle exec rake doc

[vspec]: https://github.com/kana/vim-vspec
[vim-flavor]: https://github.com/kana/vim-flavor
[vimdoc]: https://github.com/google/vimdoc
