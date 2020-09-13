#!/usr/bin/env rake

require 'rake/packagetask'
require 'json'

plugin = JSON.load(File.new('addon-info.json'))

desc 'Run tests with vader'
task :test do
  sh 'vim -c "Vader! test/*"'
end

desc 'Rebuild the documentation with vimdoc'
task :doc do
  sh 'vimdoc ./'
end

Rake::PackageTask.new(plugin['name']) do |p|
  p.version = plugin['version']
  p.need_zip = true
  p.package_files.include(['plugin/*.vim', 'autoload/*.vim', 'doc/*.txt'])
end
