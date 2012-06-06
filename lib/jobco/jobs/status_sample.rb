require "jobco/job"

module JobCo
  module Jobs
    class StatusSample < JobCo::Job
      @queue = :sample_queue

      # JobWithStatus requires instance method instead of class method
      def perform
        puts "Hi I'm a sample JobCo Resque Worker With Status!"
        puts "This will show up on worker process STDOUT, and might be logged somewhere."

        STDERR.puts "Hi I'm a sample JobCo Resque Worker !"
        STDERR.puts "This will show up on worker process STDERR, will probably end up in /dev/null."

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

      # for_schedule one place where you can do fancy stuff before your job is scheduled.
      # it should return a job.
      #
      # if you need to have some complex scheduling involving multiple jobs, look at
      # sample orchestrator instead.
      def self.for_schedule options = {}
        BasicSample.new
      end

      private

      # Resque::JobWithStatus requires a call to #failed to have proper job status
      # However, it won't terminate the job. This will.
      def job_fail reason
        failed reason.to_s
        fail reason.kind_of?(Exception) ? reason : Exception.new(reason)
      end
    end
  end
end
