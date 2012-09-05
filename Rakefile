# this rakefile is used for development/maintenance related tasks
# - launch testsuite
# - generate rdoc manually for review

# default task
task :default => :test

# doc task, see .yardopts
task "yard" do
	exec "yardoc"
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