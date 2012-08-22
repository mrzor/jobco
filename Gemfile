# this Gemfile should only be used while developping on jobco
# it is not _easily_ deployable because it presently requires a resque fork to function

source "http://rubygems.org"

gemspec

# gem 'redis-namespace', :git => "https://github.com/defunkt/redis-namespace.git"
# gem 'resque', :git => "https://github.com/defunkt/resque.git", :branch => "master"
# gem 'resque', :path => "../../resque"
gem 'resque', :git => "https://github.com/mrzor/resque", :branch => "master_and_patches"
gem 'resque-scheduler', '>= 2.0.0'
gem 'clamp', '>= 0.3.0'

group :development do
  gem 'pry'
end