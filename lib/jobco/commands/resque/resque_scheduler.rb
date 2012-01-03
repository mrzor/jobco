module JobCo
  module Commands
    class ResqueScheduler < Clamp::Command
      DefaultSchedPidfile = "/tmp/jobco-#{`whoami`.strip}/scheduler.pid"

      self.description = "Manage scheduler process"

      subcommand "stop", "guess what?" do
        option(["-p", "--pid-file"],
               "PID_FILE", "XXX PIDFILE DOC",
               :default => ENV['PIDFILE'] || DefaultSchedPidfile)
        def execute
          abort "PID file #{pid_file} not found" unless File.exists?(pid_file)
          pid = File.read(pid_file).to_i
          `kill -QUIT #{pid} 2>&1`
        end
      end

      subcommand "start", "guess what?" do
        option(["-p", "--pid-file"],
               "PID_FILE", "XXX PIDFILE DOC",
               :default => ENV['PIDFILE'] || DefaultSchedPidfile)
        option(["-b", "--background"],
              :flag, "XXX BACKGROUND DOC",
              :default => ENV['BACKGROUND'] || false)
        option(["-d", "--dynamic-schedule"],
              :flag, "Allow schedule manipulation at runtime",
              :default => ENV['DYNAMIC_SCHEDULE'] || true)
        option(["-q", "--quiet"], :flag, "Be quiet", :default => false)

        def execute
          require 'resque_scheduler'
          require 'resque/scheduler'

          require 'jobco'
          JobCo::boot

          if background?
            abort "background requires ruby >= 1.9" unless Process.respond_to?('daemon')
            Process.daemon(true)
          end

          # create pid directory if necessary
          pid_dir = File.dirname(pid_file)
          Dir.mkdir(pid_dir) unless Dir.exists?(pid_dir)

          # write pid file if not exists
          File.open(pid_file, 'w') { |f| f << Process.pid }

          # Resque::Scheduler gobbles signals and calls exit directly.
          # Still, don't SIGKILL me.
          at_exit {
            File.unlink(pid_file) if File.exists?(pid_file)
          }

          # start scheduler
          ::Resque::Scheduler.dynamic = dynamic_schedule?
          ::Resque::Scheduler.verbose = !quiet?
          ::Resque::Scheduler.run
        end
      end
    end
  end
end
