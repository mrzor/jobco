require "resque"
require "base64"

module JobCo
  # XXX: JobCo::Job is deprecated, and all of the containing code/doc should have been
  # deleted by now. Delete as soon as sure.
  #
  # === Minimal job example
  #
  # Lots can be done with as little code as this :
  #
  #    require "jobco"
  #
  #    class MyJob
  #      include JobCo::Plugins::Base
  #      @queue = 'my_queue'
  #
  #      def self.perform
  #        # anything goes here ...
  #      end
  #    end
  #
  # === Job code : arguments ?
  #
  # Let's designate `perform with arguments` as a `job method`,
  # and `perform without arguments` as a `job procedure`.
  #
  # The minimal job example above would then be a `job procedure`. 
  # A `job method` might look like the following:
  #
  #    require "jobco/job"
  #
  #    class MyParametrizedJob < JobCo::Job
  #      def perform arg_a, arg_b
  #        # anything goes here (presumably with arg_a and arg_b) ...
  #      end
  #    end
  #
  # Keep the following in mind using `job methods` (_with arguments_ that is) :
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
  # * The arguments will be encoded and be stored into redis between enqueue and perform.
  #   When passing objects as arguments, beware that the default encoder is MultiJSON.
  #   You should therefore be careful of the result of `Resque::Helpers.encode` on your
  #   arguments.
  #
  # * If all your arguments are static in nature, see `Configured jobs` parts below,
  #   as it is generally more convenient to have a `configured job procedure` instead of
  #   a `job method`.
  #
  #
  # === Configured jobs
  #
  # At enqueue time, JobCo will store the JobCo::Config object in redis,
  # that will be used once for that queued job and deleted afterwards.
  #
  # It is very convenient for values you'd otherwise hack in as 'static values'.
  #
  # If you would like to write jobs like this one:
  #
  #    def perform
  #      # ...
  #
  #      key = jobconf.webservice_api_key
  #      tok = jobconf.webservice_api_token
  #
  #      o = call_webservice(key, tok, my_call_parameters)
  #      mess_with_o(o)
  #
  #      # ...
  #    end
  #
  # You would define the key and token in your Jobfile like so:
  #
  #    job_conf "webservice_api_key" "XXX"
  #    job_conf "webservice_api_token" "42" * 42

  class Job # < ::Resque::JobWithStatus
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
