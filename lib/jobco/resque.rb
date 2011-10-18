require 'resque'
require 'resque/job_with_status'
require 'resque/scheduler'
require 'resque/status'

Resque::Status.expire_in = 7 * (72 * 60 * 60) # A week, in seconds
Resque::Scheduler::dynamic = true
