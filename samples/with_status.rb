require "jobco"
require "resque-status"

class StatusSample
  include JobCo::Plugins::Base
  include JobCo::Plugins::Status

  # JobWithStatus requires instance method instead of class method
  def perform
    puts "Hi I'm a sample JobCo Resque Worker With Status!"
    puts "This will show up on worker process STDOUT, and might not be logged."

    # this will just update the status line before we roll
    tick "Loading ..."

    global_redis = Redis.new
    job_fail "Why, no redis ?" unless global_redis

    redis = Redis::Namespace.new("status_sample_job", :redis => global_redis)
    job_fail "Why, no redis namespace ?" unless redis

    (0..300).each do |i|
      redis.sadd("flushme", "%03i/300 - %s" % [i, Time.now.to_s])
      sleep 0.2
      at((100 * i / 300).floor, 100, "Dancing the sample dance") if i % 3 == 0
    end

    completed "This is JobCo Sample Resque Worker. I have completed."
  end
end
