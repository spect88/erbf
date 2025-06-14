# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"
require "syntax_tree/rake_tasks"
require "rubocop/rake_task"

Minitest::TestTask.create

stree_config =
  proc { |t| t.source_files = FileList[%w[Gemfile Rakefile lib/**/*.rb test/**/*.rb *.gemspec]] }
SyntaxTree::Rake::CheckTask.new(&stree_config)
SyntaxTree::Rake::WriteTask.new(&stree_config)

RuboCop::RakeTask.new

desc "Run all code checks"
task check: %i[rubocop stree:check test]

desc "Run all automated fixes"
task fix: %i[stree:write rubocop:autocorrect_all]

task default: :check
