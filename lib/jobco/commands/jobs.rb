require "jobco/jobs"

module JobCo
  module Commands
    class Jobs < Clamp::Command
      option ["-j", "--jobfile"], "JOBFILE", "Use a specific Jobfile (default: looks up for Jobfile in current dir or any parent)", :default => JobCo::Jobfile.find

      subcommand ["ls", "list"], "available jobs" do
        def execute
          puts "Jobs known to JobCo:"
          JobCo::boot_and_load(jobfile)
          JobCo::Jobs::available_jobs.each { |x| puts " * #{x}" }
        end
      end

      subcommand ["s", "status"], "XXX job statuses" do
        def execute
          # XXX: moar pretty print !
          puts "Last status:"
          JobCo::boot_and_load(jobfile)
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
          JobCo::boot_and_load(jobfile)
          job_class = JobCo::Jobs::select_job(name)

          job_id = JobCo::enqueue(job_class)
          puts "Queued #{job_class}, ID=#{job_id}"
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
          JobCo::boot_and_load(jobfile)
          job_class = JobCo::Jobs::select_job(name)

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
