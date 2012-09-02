require "jobco"

class BasicSample
  include JobCo::Plugins::Base

  @queue = "jobco_samples"

  def self.perform
    # this job does nothing when being used for testing
    return if $TESTING

    puts "Hi I'm sample JobCo Resque code !"
    puts "This will show up on worker process STDOUT, and might not be logged."
    puts "I will now waste CPU cycles and Redis memory for one minute ..."

    (0..300).each do |i|
      Resque.redis.sadd("flushme", "%03i/300 - %s" % [i, Time.now.to_s])
      sleep 0.2
    end

    puts "This is JobCo Sample Resque code. I have completed."
  end
end