require "resque"
require "resque/job_with_status"
require "base64"

module JobCo
  # = JobCo::Job is what you inherit from
  #
  # Forced inheritance : it comes from JobWithStatus.
  # In another dimension, we would have enjoyed fancy automagical "include JobCo::Fu".
  #
  # = Example
  #
  # XXX see lib/jobco/jobs/status_sample.rb
  #
  # = Features and side effects
  #
  # == Configuration
  #
  # JobCo::Job marshals JobCo::Config (an openstruct) to redis at enqueue
  # and loads it back into @jobco at perform time. Use this at will to reuse
  # configuration defined in your Jobfile.
  #
  # == require_rails helper
  #

  class Job < ::Resque::JobWithStatus
    attr_reader :jobconf

    # Call this manually in your perform() code if you operate a resque deployment
    # where some workers load rails and some don't.
    #
    # For most uses, it's best to simply use the Jobfile "require_rails" job_conf
    # entry. See Jobfile documentation and/or sample.
    #
    # This assumes that your Jobfile is at the root of your Rails application,
    # next to your Gemfile.
    def self.require_rails
      highway_to_rails = Jobfile.relative_path("config", "environment.rb")
      unless File.exists?(highway_to_rails)
        fail "where is rails ? I thought it was '#{highway_to_rails}'"
      end

      require highway_to_rails
      Rails.application.eager_load!
    end

    # Call this liberally in your perform() code to retrieve global
    # (but still environment dependant) configuration.
    #
    # Job configuration is saved each time a job is enqueued, and never
    # changed once a UUID have been set. This means that configuration
    # changes only apply to jobs enqueued/scheduled after that.
    def jobconf
      return @jobconf if @jobconf

      require "base64"
      raw_conf = JobCo::redis.hget("conf", @uuid)

      unless raw_conf
        fail "JobCo internal: Could not load configuration for uuid '#{@uuid}'. Report this."
        return nil
      end

      @jobconf = Marshal.load(Base64.decode64(raw_conf))
      JobCo::redis.hdel("conf", @uuid)
      @jobconf
    end

    # A JobCo-using developer would not call this directly.
    # For clearer semantics, prefer `JobCo::enqueue(YourJob)`.
    #
    # Calling create will result in job enqueing.
    def self.create *args
      self.enqueue(self, *args)
    end

    # A JobCo-using developer would not call this directly.
    # Overrides Resque::JobWithStatus
    def self.perform(uuid = nil, *args)
      uuid ||= Resque::Status.generate_uuid
      instance = new(uuid)
      instance.send(:jobco_boot)
      instance.tick "Perform job #{uuid}"
      instance.safe_perform! *args
      instance
    end

    # A JobCo-using developer would not call this directly.
    # Overrides Resque::JobWithStatus
    def self.enqueue(klass, *args)
      Config.uuid = ::Resque::Status.create
      packed_config = Base64.encode64(Marshal.dump(JobCo::Config))
      JobCo::redis.hset("conf", Config.uuid, packed_config)
      ::Resque.enqueue(klass, Config.uuid, *args)
      Config.uuid
    end

    # A JobCo-using developer would not call this directly.
    # Overrides Resque::JobWithStatus
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

    # A JobCo-using developer would not call this directly.
    #
    # Job::scheduled is a Resque::Scheduler API that allows
    # interoperation with Resque::JobWithStatus
    def self.scheduled(queue, klass, *args)
      @queue = queue
      self.create(*args)
    end

    private

    def jobco_boot
      JobCo::redis.hset("last_class_uuid", self.class, uuid)

      conf = jobconf()
      if conf and conf.require_rails == :each_time
        tick "Loading rails..."
        Job::require_rails
      end
    end
  end
end
