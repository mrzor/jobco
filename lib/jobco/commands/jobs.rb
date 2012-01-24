require "jobco/jobs"

module JobCo
  module Commands
    class Jobs < Clamp::Command
      option ["-j", "--jobfile"], "JOBFILE", "Use a specific Jobfile (default: looks up for Jobfile in current dir or any parent)"

      subcommand ["ls", "list"], "available jobs" do
        def execute
          STDOUT << "Loading JobCo ... "
          JobCo::boot
          JobCo::Jobs::require_files
          STDOUT.puts "ok."

          puts "Jobs known to JobCo:"
          JobCo::Jobs::available_jobs.each { |x| puts " * #{x}" }
        end
      end

      subcommand ["s", "status"], "XXX job statuses" do
        def execute
          # XXX: moar pretty print !
          puts "Last status:"
          puts JobCo::Jobs::status.inspect
        end
      end

      subcommand ["q", "enqueue"], "manually enqueue a job" do
        self.description = "Manual enqueuing (one shot). Does not support parameters."
        option(["-e", "--every"], "PERIOD",
               "XXX every period doc",
               :default => "15m")

        parameter "NAME", "name of the job class to run"
        def execute
          job_class = JobCo::Jobs::select_job_class(name)
          if job_class.ancestors.include?(::Resque::JobWithStatus)
            ::Resque::Status.expire_in = 7 * (72 * 60 * 60) # A week, in seconds
            job_id = job_class.create
            puts "Queue JobWithStatus ID=#{job_id}"
          elsif true # FIXME: check that class has a perform method
            ::Resque.enqueue(c)
          else
            abort "unsupported class #{job_class} for jobco enqueuing"
          end
        end
      end

      subcommand "q-every", "manually schedule a recurring job" do
        self.description = "Manual job scheduling. Does not support parameters."
        option(["-e", "--every"], "PERIOD",
               "XXX every period doc",
               :default => "15m")
        option(["-n", "--schedule-name"], "SCHEDULE_NAME",
               "XXX schedule name doc",
               :default => "jobco_schedule_classname")
        parameter "NAME", "name of the job class to run"

        def execute
          require 'resque_scheduler'
          job_class = JobCo::Jobs::select_job_class(name)

          if schedule_name == "jobco_schedule_classname"
            schedule_name = "jobco_schedule_#{job_class.to_s.downcase}"
          end

          schedule_opts = {
            "every" => every,
            "custom_job_class" => job_class,
            "queue" => ::Resque::queue_from_class(job_class),
            "args" => {},
            "description" => "Jobco manual schedule at #{Time.now.strftime("%F %T")}"
          }

          ::Resque::set_schedule(schedule_name, schedule_opts)
          puts "Schedule parameters:"
          schedule_opts.each_pair { |pair| puts "    %-20s %s" % pair }
          puts "Jobco successfully configured schedule '#{schedule_name}' for job class #{job_class}."
        end
      end
    end
  end
end
