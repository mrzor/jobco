# this rakefile is only used for development related tasks
# - launch testsuite
# - generate rdoc manually for review

# default task
task :default => :test

# # rdoc task
# require 'rdoc/task'
# RDoc::Task.new do |rd|
# 	rd.main = "README.md"
# 	rd.rdoc_files.include("README.md", "lib/**/*.rb", "samples/*.rb")
# YARD

require "yard"
require "yard/rake/yardoc_task"
YARD::Rake::YardocTask.new do |t|
	# require "pry"
	# binding.pry
  t.files   = ['lib/*.rb', 'lib/jobco/*.rb', 'lib/jobco-plugins/*.rb', "samples/*.rb"]   # optional
  # t.options = ['--any', '--extra', '--opts'] # optional
end

# test task
require 'rake/testtask'
Rake::TestTask.new do |test|
  test.verbose = true
  test.libs << "test"
  test.libs << "lib"
  test.test_files = FileList['test/**/*_test.rb']
end

# - FIXME: cook rubygem and upload it