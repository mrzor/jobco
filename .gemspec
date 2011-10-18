# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name        = "jobco"
  s.version     = "0.0.1"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Elie Zor"]
  s.email       = ["elie@letitcast.com"]
  s.homepage    = "http://github.com/iconocast/jobcenter"
  s.summary     = "The best way to launch jobs for LIC"
  s.description = "Jobcenter provides command & control for LIC resque jobs, and more."

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "bundler"

  s.add_dependency('resque', '>= 1.17.1')
  s.add_dependency('resque-scheduler', '>= 2.0.0d')
  s.add_dependency('resque-status', '>= 0.2.3')
  s.add_dependency('clamp', '>= 0.2.3')

  s.files        = Dir.glob("lib/**/*") + Dir.glob("bin/jobco*")
  s.executables  = ['jobco']
  s.require_path = 'lib'
end
