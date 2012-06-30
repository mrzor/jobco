require "jobco"

class BasicSample
  include JobCo::Plugins::Base

  @queue = "jobco_samples"

  def self.perform
    puts "Hi I'm a sample JobCo Resque Worker !"
    puts "This will show up on worker process STDOUT, and might not be logged."
    puts "I will now waste CPU cycles and Redis memory for one minute ..."

    (0..300).each do |i|
      Resque.redis.sadd("flushme", "%03i/300 - %s" % [i, Time.now.to_s])
      sleep 0.2
    end

    puts "This is JobCo Sample Resque Worker. I have completed."
  end
end