# erbf

A formatter for your `.html.erb` files.

> [!CAUTION]
> erbf is still in alpha stages of development. Use at your own risk.

## Features

#### Style similar to Prettier's

Many teams use prettier and it'd be strange if `.html.erb` files were formatted
differently than `.html` files in the same project.

If some HTML (without ERB tags) gets formatted differently than Prettier with
default settings would have done it, that's a bug.

Support for `--html-whitespace-sensitivity` may be added in the future.

#### Formats Ruby code

SyntaxTree will be used if it's available. If you don't want your Ruby code
reformatted, you can disable it in the config file.

#### Formats other embedded languages

The code within `<script>` and `<style>` tags will be formatted if `prettier`
is installed under the `node_modules` directory.

You can also specify any other formatter that has a CLI which can format STDIN.

#### CLI

Format/check/write specified files (or STDIN)

#### Planned

- Some kind of "no-format" comment support
- Support for any other Ruby formatter
- Ruby LSP Plugin
- SyntaxTree Plugin
- Rake tasks
- Website with examples of: formatting, configuration, integration with other tools and IDEs

## Installation

Install the gem, either as your project's dependency or globally:

```sh
bundle add erbf --group "development, test"
# or
gem install erbf
```

## Usage

```sh
# format all *.html.erb files in a directory
erbf directory

# check if all files are formatted
erbf -c directory

# auto-format all files
erbf -w directory

# auto-format files with a different extension
erbf 'directory/**/*.erb'

# format stdin
erbf < file.erb
```

You can configure it via a config file in your repo:

```yaml
# .erbf.yml or config/erbf.yml
line_length: 80
ruby:
  formatter: syntax_tree
  syntax_tree_plugins:
    - plugin/single_quotes
embedded:
  - types:
      - text/javascript
      - module
    command: prettier --stdin-filepath file.js --print-width %<line_length>d
  - types:
      - text/css
    command: prettier --stdin-filepath file.css --print-width %<line_length>d
```

## Development

```sh
# Install dependencies
bin/setup

# Run the linter, formatter and tests
bundle exec rake

# Run a REPL
bin/console

# Install the gem locally
bundle exec rake install

# Release a new version (after updating version.rb)
bundle exec rake release
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/spect88/erbf.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
