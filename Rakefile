# frozen_string_literal: true

require "bundler/gem_tasks"
require "reek/rake/task"
require "rspec/core/rake_task"
require "rubocop/rake_task"

SOURCES = FileList["lib/**/*.rb", "exe/*", "spec/**/*.rb"].exclude("spec/fixtures/**/*")

# The fixture project's own specs are run by mutato, not by rake.
RSpec::Core::RakeTask.new(:spec) do |task|
  task.exclude_pattern = "spec/fixtures/**/*_spec.rb"
end
RuboCop::RakeTask.new
Reek::Rake::Task.new do |task|
  task.source_files = SOURCES
end

desc "Check for duplicated code"
task :flay do
  require "flay"
  flay = Flay.run(SOURCES.to_a)
  flay.analyze
  next if flay.total.zero?

  flay.report
  abort "flay: total score #{flay.total}, must be 0"
end

desc "Run mutato on its own library"
task :mutants do
  # Specs tagged subprocess run mutato in another process: they cannot judge an
  # in-process mutant, and must not start another run.
  specs = "spec --exclude-pattern spec/fixtures/**/*_spec.rb --tag ~subprocess"
  ruby "exe/mutato", "run", "lib", "--spec", specs
end

task default: %i[spec rubocop reek flay mutants]
