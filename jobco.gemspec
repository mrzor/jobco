# -*- encoding: utf-8 -*-


Gem::Specification.new do |s|
  s.name        = "jobco"
  s.version     = "0.2.0"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Elie Zor"]
  s.email       = ["elie@letitcast.com"]
  s.homepage    = "http://github.com/mrzor/jobco"
  s.summary     = "Resque distribution aimed at ease of use"
  s.description = "Jobco provides command & control for resque jobs, and much needed sugar."

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "jobco"

  s.add_dependency('resque', '>= 1.20.1')
  s.add_dependency('resque-scheduler', '>= 2.0.0f')
  s.add_dependency('clamp', '>= 0.3.0')
  s.add_dependency('uuid', '~> 2.3')

  libglob = File::join(File::dirname(__FILE__), "lib/**/*")
  binglob = File::join(File::dirname(__FILE__), "bin/jobco*")

  s.files        = Dir[libglob] + Dir[binglob]
  s.executables  = ['jobco']
  s.require_path = 'lib'
end
