require "jobco"

class StatusSample
  include JobCo::Plugins::Base
  include JobCo::Plugins::Status

  @queue = "jobco_samples"

  # xxx
  def self.perform
    puts "Hi I'm a sample JobCo Resque Worker With Status!"
    puts "This will show up on worker process STDOUT, and might not be logged."

    # this will just update the status line before we roll
    tick "Loading ..."

    redis = Redis::Namespace.new("jobco_samples", :redis => Resque.redis)

    (0..30).each do |i|
      redis.sadd("flushme", "%03i/300 - %s" % [i, Time.now.to_s])
      sleep 0.2
      at(i / 3, 100, "Dancing the sample dance") if i % 3 == 0
    end

    completed "This is JobCo Sample Resque Worker. I have completed."
  end
end
