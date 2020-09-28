# Contributing

## Testing

Tests are written for [vader.vim][vader].
The test suite can be run via the rake task:

	bundle install
	bundle exec rake test

Or by specifying the tests to run on the command line:

    vim -c "Vader! test/*"

## Documentation

The documentation in `doc/` is generated from the plug-in source code via
[vimdoc][vimdoc]. Do not edit `doc/<plugin>.txt` directly. Refer to the
existing inline documentation as a guide for documenting new code.

The help doc can be rebuilt by running:

	bundle exec rake doc

[vader]: https://github.com/junegunn/vader.vim
[vimdoc]: https://github.com/google/vimdoc
