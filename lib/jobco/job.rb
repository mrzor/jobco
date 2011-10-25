require "resque"
require "resque/job_with_status"

module JobCo
  # forced inheritance : it comes from JobWithStatus.
  # in another dimension, we would have enjoyed fancy automagical "include JobCo::Fu"
  class Job < ::Resque::JobWithStatus
    def self.create options = {}
      self.enqueue(self, options)
    end

    def self.enqueue(klass, options = {})
      uuid = ::Resque::Status.create :options => options
      rn = Redis::Namespace.new("jobco", :redis => ::Resque.redis.redis)
      rn.hset("conf", uuid, JobCo::Config.to_json)
      ::Resque.enqueue(klass, uuid, options)
      uuid
    end

    def jobconf
      return @jobconf if @jobconf
      rn = Redis::Namespace.new("jobco", :redis => ::Resque.redis.redis)
      @jobconf = JSON.parse(rn.hget("conf", @uuid))
      rn.hdel("conf", @uuid)
      @jobconf
    end
  end
end
