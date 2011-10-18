require "jobco/jobs"

module JobCo
  module Commands
    class Jobs < Clamp::Command
      subcommand ["ls", "list"], "available jobs" do
        def execute
          puts "Jobs known to JobCo:"
          available_jobs.each { |x| puts " * #{x}" }
        end
      end

      subcommand ["q", "enqueue"], "manually enqueue a job" do
        self.description = "Manual enqueuing ignores scheduling, and does not support parameters."
        parameter "NAME", "name of the job to run"
        def execute
          c = available_jobs.select { |j| j.to_s.downcase.include?(name) }
          if c.size > 1
            abort "Different jobs match `#{name}': #{c.join(', ')}"
          elsif c.empty?
            abort "No jobs are matching `#{name}'. Use `jobs ls' command."
          end
          enqueue c.first
        end
      end

      protected

      def available_jobs
        JobCo::Jobs.constants.map do |c|
          JobCo::Jobs.const_get(c)
        end.select { |c| c.is_a?(Class) }

      end

      def enqueue klass
        if klass.ancestors.include?(::Resque::JobWithStatus)
          ::Resque::Status.expire_in = 7 * (72 * 60 * 60) # A week, in seconds
          job_id = klass.create
          puts "Queue JobWithStatus ID=#{job_id}"
        elsif true # FIXME: check that class has a perform method
          ::Resque.enqueue(c)
        else
          abort "unsupported class #{klass} for enqueuing"
        end
      end
    end
  end
end
