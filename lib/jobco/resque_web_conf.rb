# FIXME: be ENV["RESQUECONFIG"] sensitive
#        see https://github.com/defunkt/resque/blob/master/bin/resque-web
#        see jobco/commands/resque

require 'resque/status_server'
require 'resque_scheduler'
Resque::Scheduler::dynamic = true

require "jobco"
JobCo::boot
