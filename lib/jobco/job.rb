require "resque"
require "resque/job_with_status"

module JobCo
  # forced inheritance : it comes from JobWithStatus.
  # in another dimension, we would have enjoyed fancy automagical "include JobCo::Fu"
  #
  # JobCo::Job marshalizes JobCo::Config (an openstruct) to redis at enqueue
  # and (lazily) loads it back into @jobco at runtime
  class Job < ::Resque::JobWithStatus
    def self.create options = {}
      self.enqueue(self, options)
    end

    def self.enqueue(klass, options = {})
      require "base64"

      uuid = ::Resque::Status.create :options => options
      rn = Redis::Namespace.new("jobco", :redis => ::Resque.redis.redis)
      rn.hset("conf", uuid, Base64.encode(Marshal.dump(JobCo::Config)))
      ::Resque.enqueue(klass, uuid, options)
      uuid
    end

    def jobconf
      return @jobconf if @jobconf

      require "base64"
      rn = Redis::Namespace.new("jobco", :redis => ::Resque.redis.redis)
      @jobconf = Marshal.load(Base64.decode(rn.hget("conf", @uuid)))
      rn.hdel("conf", @uuid)
      @jobconf
    end
  end
end
