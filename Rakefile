# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new(:spec) do |t|
  t.libs << 'spec'
  t.test_files = FileList['spec/**/*_spec.rb']
end

desc 'Start the visual preview server on port 9292'
task :server do
  sh 'bundle exec rackup -p 9292'
end

task default: :spec
