# this Gemfile should only be used while developping on jobco
source "http://rubygems.org"

gemspec

# gem 'redis-namespace', :git => "https://github.com/defunkt/redis-namespace.git"
# gem 'resque', :git => "https://github.com/defunkt/resque.git", :branch => "master"
# gem 'resque', :path => "../../resque"
gem 'resque', :git => "https://github.com/mrzor/resque", :branch => "master_and_patches"

group :development do
  gem 'pry'
  gem 'yard'
  gem 'redcarpet'
  # gem 'grit'
end

group :test do
  gem "rake"
  gem "rack-test", "~> 0.5"
  gem "mocha", "~> 0.9.7"
  # gem "yajl-ruby", "~>0.8.2", :platforms => :mri
  # gem "json", "~>1.5.3", :platforms => [:jruby, :rbx]
  # gem "hoptoad_notifier"
  # gem "airbrake"
  gem "i18n"
  gem "minitest"
end
