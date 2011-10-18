require 'resque/tasks'
require 'resque_scheduler/tasks'

namespace :resque do
  task :setup => :environment do
    require "jobco/resque"

    # Empty schedule (jobs will be dynamically scheduled elsewhere)
    Resque::schedule = {}
  end
end