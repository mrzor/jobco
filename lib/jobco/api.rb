module JobCo
  # = JobCo API =
  #
  # API is a big word that more or less says the following
  # is what you would like to use while writing application code.
  #
  # Application code means your Rack/Sinatra/Rails application,
  # or a rake task, or a clamp/thor CLI tool, or what have you.
  #
  # API functions, such as , are mixed in the JobCo module,
  # meaning you could call `JobCo::API::enqueue` as `JobCo::enqueue`.
  module API
    # Regular Resque style enqueue
    # This will fire up the job exactly once, ASAP
    def enqueue job_class, *args
      job_class.create(*args)
    end

    # resque-scheduler enqueue_at
    #
    # Details at:
    # https://github.com/bvandenbos/resque-scheduler/blob/master/README.markdown
    def enqueue_at
    end

    # resque-scheduler enqueue_in
    #
    # Details at:
    # https://github.com/bvandenbos/resque-scheduler/blob/master/README.markdown
    def enqueue_in
    end

    # XXX: dequeue?

    # resque-scheduler dynamicly scheduled job
    #
    # recognized options keys:
    # `:args => [arg1, arg2]` arguments for your perform() call if any
    # `:description => 'blabla'` defaults to time of call to this method
    # `:schedule_name => 'unique_schedule_name' useful if you need to schedule
    # same job several times
    #
    # XXX: more documentation needed
    def schedule job_class, options = {}, *args
      require 'resque_scheduler'
      schedule_opts = {
        "custom_job_class" => job_class.to_s,
        "queue" => ::Resque::queue_from_class(job_class),
        "args" => [], # XXX FIXME || *args
        "description" => "Jobco scheduled at #{Time.now.strftime("%F %T")}",
        "schedule_name" => "schedule_#{job_class}",
      }.merge(options)

      # no defaults for those. pick one.
      unless schedule_opts.key?("every") or schedule_opts.key?("cron")
        fail "need 'every' or 'cron' key"
      end

      ::Resque::set_schedule(schedule_opts["schedule_name"], schedule_opts)
      schedule_opts["schedule_name"]
    end

    # non functional JobCo helper
    def unschedule schedule_name
      ::Resque::remove_schedule(schedule_name)
    end
  end
end
