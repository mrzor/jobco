require "resque"
require "resque/job_with_status"

module JobCo
  # forced inheritance : it comes from JobWithStatus.
  # in another dimension, we would have enjoyed fancy automagical "include JobCo::Fu"
  #
  # JobCo::Job marshalizes JobCo::Config (an openstruct) to redis at enqueue
  # and (lazily) loads it back into @jobco at runtime
  class Job < ::Resque::JobWithStatus
    attr_reader :jobconf

    def self.create *args
      self.enqueue(self, *args)
    end

    # Overrides Resque::JobWithStatus
    def self.perform(uuid = nil, *args)
      uuid ||= Resque::Status.generate_uuid
      instance = new(uuid)

      jobconf = instance.jobconf
      if jobconf.require_rails == :each_time
        instance.tick "Loading rails..."
        require_rails
      end

      instance.tick "Perform job #{uuid}"
      instance.safe_perform! *args
      instance
    end

    # overrides of Resque::JobWithStatus
    def self.enqueue(klass, *args)
      require "base64"

      Config.uuid = ::Resque::Status.create
      rn = Redis::Namespace.new("jobco", :redis => ::Resque.redis.redis)

      rn.hset("conf", Config.uuid, Base64.encode64(Marshal.dump(JobCo::Config)))
      ::Resque.enqueue(klass, Config.uuid, *args)
      Config.uuid
    end

    # overrides Resque::JobWithStatus
    def safe_perform! *args
      set_status({'status' => 'working'})
      perform *args
      completed unless status && status.completed?
      on_success if respond_to?(:on_success)
    rescue Killed
      logger.info "Job #{self} Killed at #{Time.now}"
      Resque::Status.killed(uuid)
      on_killed if respond_to?(:on_killed)
    rescue => e
      logger.error e
      failed("The task failed because of an error: #{e}")
      if respond_to?(:on_failure)
        on_failure(e)
      else
        raise e
      end
    end

    # require Rails 3, fool.
    def self.require_rails
      highway_to_rails = Jobfile.relative_path("config", "environment.rb")
      unless File.exists?(highway_to_rails)
        fail "where is rails ? I thought it was '#{highway_to_rails}'"
      end

      require highway_to_rails
      Rails.application.eager_load!
    end

    def jobconf
      return @jobconf if @jobconf

      require "base64"
      rn = Redis::Namespace.new("jobco", :redis => ::Resque.redis.redis)
      @jobconf = Marshal.load(Base64.decode64(rn.hget("conf", @uuid)))
      rn.hdel("conf", @uuid)
      @jobconf
    end
  end
end
