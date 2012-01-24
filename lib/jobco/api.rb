module JobCo
  # JobCo::API regroup functions that programatically trigger jobs.
  # See JobCo::Jobs for functions that provide information about jobs.
  #
  # === Immediate enqueue
  #
  # The simplest form of programatic job control is _enqueuing_, a fundamental
  # Resque operation. See #enqueue and (DOC FIXME: link to Resque doc)
  #
  # === Postponed enqueue
  #
  # Resque Scheduler, an extension bundled with JobCo, expands the scope
  # to _deferred_ and _scheduled_ jobs. Deferred or scheduled jobs are
  # queued at a later point in time - that you specify.
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
    # This will fire up the job exactly once, ASAP
    # === Examples
    #
    #   # From your controllers or models
    #   JobCo.enqueue(Jobs::CrushImages, image.id)
    #   JobCo.enqueue(Jobs::WelcomeEmail, user.id)
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

    # resque-scheduler dynamicly scheduled job
    # XXX: more documentation needed
    def schedule job_class, options = {}
      require 'resque_scheduler'
      schedule_opts = {
        "custom_job_class" => job_class.to_s,
        "queue" => ::Resque::queue_from_class(job_class),
        "args" => [],
        "description" => "Jobco scheduled at #{Time.now.strftime("%F %T")}",
        "schedule_name" => "schedule_#{job_class}"
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
