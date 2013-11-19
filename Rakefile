require 'fileutils'
require 'rspec/core/rake_task'

desc "Run spec suite (uses Rspec2)"
RSpec::Core::RakeTask.new(:spec) { |t|}
task :test => :spec
task :default => :spec

desc "Run specs with RCov"
RSpec::Core::RakeTask.new(:rcov) do |t|
    t.rcov = true
      t.rcov_opts = ['--exclude', 'spec']
end

desc "Build the gem"
task :gem do
    sh 'gem build *.gemspec'
end

task :doc do
    sh 'yard'
end
