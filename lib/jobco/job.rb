require "resque"
require "resque/job_with_status"
require "base64"

module JobCo
  # === Minimal job example
  #
  # Lots can be done with as little code as this :
  #
  #    require "jobco/job"
  #
  #    class MyJob < JobCo::Job
  #      @queue = 'my_queue'
  #
  #      def perform
  #        # anything goes here ...
  #      end
  #    end
  #
  # === Job code : arguments ?
  #
  # Let's designate `perform with arguments` as a `job method`,
  # and `perform without arguments` as a `job procedure`.
  #
  # The minimal job example above is a `job procedure`. A `job method` might
  # look like the following:
  #
  #    require "jobco/job"
  #
  #    class MyParametrizedJob < JobCo::Job
  #      def perform arg_a, arg_b
  #        # anything goes here ...
  #      end
  #    end
  #
  # Keep the following in mind using `job methods` :
  #
  # * Worker procedures can be scheduled using `jobco jobs enqueue` and similar
  #   tools.
  #
  # * Worker methods can only be programatically scheduling using the JobCo::API
  #   routines.
  #
  # * It is your responsibility to enqueue a worker method with the correct number
  #   of arguments. If you fail to do so, the worker process will fail to execute
  #   your job.
  #
  # * The arguments will be serialized to JSON format. When passing objects as arguments
  #   to JobCo::enqueue (and its siblings), be wary of what #to_json will yield for your
  #   arguments.
  #
  # * If all your arguments are static in nature, see `Configured jobs` parts below,
  #   as it can be helpful in order to convert a `job method` into a 
  #   `configured job procedure`.
  #
  # === Fancier jobs - with status!
  #
  # Inside your perform code, you might want to use the following :
  #
  # * Live status report : #tick , #at
  # * End status report : #completed , #failed
  #
  # XXX see lib/jobco/jobs/status_sample.rb
  #
  # === Configured jobs
  #
  # At enqueue time, JobCo will store the JobCo::Config object in redis,
  # that will be used once for that queued job and deleted afterwards.
  #
  # Let's assume your Jobfile contains the following:
  #
  #    job_conf "webservice_api_key" "XXX"
  #    job_conf "webservice_api_token" "42" * 42
  #
  # Then, it is safe to query the configured values from your jobs like so:
  #
  #    def perform
  #      # ...
  #
  #      key = jobconf.webservice_api_key
  #      tok = jobconf.webservice_api_token
  #
  #      o = webservice_call(key, tok, my_call_parameters)
  #      mess_with_o(o)
  #
  #      # ...
  #    end
  #
  class Job < ::Resque::JobWithStatus
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
    def self.create *args # :nodoc:
      self.enqueue(self, *args)
    end

    # A JobCo-using developer would not call this directly.
    # Overrides Resque::JobWithStatus
    def self.perform(uuid = nil, *args)  # :nodoc:
      uuid ||= Resque::Status.generate_uuid
      instance = new(uuid)
      instance.send(:jobco_boot)
      instance.tick "Perform job #{uuid}"
      instance.safe_perform! *args
      instance
    end

    # A JobCo-using developer would not call this directly.
    # Overrides Resque::JobWithStatus
    def self.enqueue(klass, *args) # :nodoc:
      Config.uuid = ::Resque::Status.create
      packed_config = Base64.encode64(Marshal.dump(JobCo::Config))
      JobCo::redis.hset("conf", Config.uuid, packed_config)
      ::Resque.enqueue(klass, Config.uuid, *args)
      Config.uuid
    end

    # A JobCo-using developer would not call this directly.
    # Overrides Resque::JobWithStatus
    def safe_perform! *args # :nodoc:
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
    def self.scheduled(queue, klass, *args) # :nodoc:
      @queue = queue
      self.create(*args)
    end

    # This is called when someone subclasses JobCo::Job
    def self.inherited subclass # :nodoc:
      JobCo::Jobs::register_available_job(subclass)
    end

    private

    def jobco_boot # :nodoc:
      JobCo::redis.hset("last_class_uuid", self.class, uuid)

      conf = jobconf()
      if conf and conf.require_rails == :each_time
        tick "Loading rails..."
        Job::require_rails
      end
    end
  end
end
