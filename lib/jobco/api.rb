module JobCo
  ##
  # JobCo::API regroup functions that programatically trigger jobs.
  # See JobCo::Jobs for functions that provide information about jobs.
  #
  # === Immediate enqueue
  #
  # The simplest form of programatic job control is _enqueuing_. Enqueuing results 
  # in deferred job performing inside a worker process. JobCo's implementation is a 
  # simple forward to Resque.enqueue - calling JobCo.enqueue() and Resque.enqueue() 
  # work in the same fashion.
  # See #enqueue and (DOC FIXME: link to Resque doc)
  #
  # === Deferred enqueue
  #
  # Resque Scheduler, a resque plugin, is supported and wrapped up by JobCo.
  # It allows you to either _defer_ jobs (to have them enqueued at a later time) or
  # _schedule_ them (to have them enqueued at a specific time, in a possibly recurring way).
  # DOC FIXME: link to resque-scheduler docs
  #
  # === Syntax
  #
  # Note that all JobCo::API functions are mixed in the JobCo module.
  # The following lines are therefore equivalent:
  #
  #   JobCo::API::enqueue(MyJobs::Demo)
  #   JobCo.enqueue(MyJobs::Demo) # one and the same
  #
  module API
    # Regular Resque style enqueue
    #
    # This will fire up the job exactly once, ASAP.
    # Should return UUID if job has status plugin, true otherwise. (?)
    #
    # === Examples
    #
    #   # From your controllers or models
    #   JobCo.enqueue(Jobs::CrushImages, image.id)
    #   JobCo.enqueue(Jobs::WelcomeEmail, user.id)
    def enqueue job_class, *args
      ::Resque.enqueue(job_class, *args)
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

    # removes a schedule entry from the schedule table
    def unschedule schedule_name
      require 'resque_scheduler'
      ::Resque::remove_schedule(schedule_name)
    end
  end
end
