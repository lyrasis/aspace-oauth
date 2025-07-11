# frozen_string_literal: true

require "rake/testtask"

desc "Run tests"
Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "frontend/lib"
  t.test_files = FileList["test/unit/**/*_test.rb"]
  t.verbose = true
end

desc "Run tests with coverage"
task :test_with_coverage do
  ENV["COVERAGE"] = "true"
  Rake::Task[:test].invoke
end

desc "Run linter"
task :lint do
  sh "standardrb"
end

desc "Fix linting issues"
task :lint_fix do
  sh "standardrb --fix"
end

desc "Run all quality checks"
task quality: [:lint, :test]

task default: :test
