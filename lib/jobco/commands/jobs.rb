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

      subcommand "enqueue", "manually enqueue a job" do
        self.description = "Manual enqueuing ignores scheduling, and does not support parameters."
        parameter "NAME", "name of the job to run"
        def execute
          c = available_jobs.select { |j| j.to_s.downcase.include?(name) }
          if c.size > 1
            puts "Different jobs match `#{name}':"
            c.each { |x| puts " * #{x}" }
          end
          ::Resque.enqueue(c)
        end
      end

      protected

      def available_jobs
        JobCo::Jobs.constants.map do |c|
          JobCo::Jobs.const_get(c)
        end.select { |c| c.is_a?(Class) }

        # FIXME: check that class has a perform method
      end
    end
  end
end
