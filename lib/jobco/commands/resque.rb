require 'resque'
require 'resque_scheduler'

require 'clamp'

module JobCo
  module Commands
    class Resque < Clamp::Command
      subcommand "run_worker", "forks a worker in the background" do
        option(["-q", "--quiet"], :flag, "Be quiet", :default => false)
        option(["-i", "--interval"],
               "INTERVAL", "Interval at which ",
               :default => (ENV['INTERVAL'] || 5).to_i)
        option(["-b", "--background"],
              :flag, "XXX BACKGROUND DOC",
              :default => ENV['BACKGROUND'] || false)
        option(["-Q", "--queues"],
               "QUEUES", "Job queue(s) the worker is serving.",
               :default => (ENV['QUEUES'] || ENV['QUEUE'] || "*").to_s.split(','))
        option(["-p", "--pidfile"],
               "PIDFILE", "XXX PIDFILE DOC",
               :default => ENV['PIDFILE'])

        def execute
          require 'jobco/jobs'
          require 'resque/worker'

          if background?
            abort "background requires ruby >= 1.9" unless Process.respond_to?('daemon')
            Process.daemon(true)
          end

          worker = ::Resque::Worker.new(queues)
          worker.verbose = !quiet?
          worker.work(interval)
          # worker.very_verbose = true
        end
      end

      subcommand "run_scheduler", "forks a resque::scheduler process" do
        option(["-b", "--background"],
              :flag, "XXX BACKGROUND DOC",
              :default => ENV['BACKGROUND'] || false)
        option(["-d", "--dynamic-schedule"],
              :flag, "Allow schedule manipulation at runtime",
              :default => ENV['DYNAMIC_SCHEDULE'] || false)
        option(["-q", "--quiet"], :flag, "Be quiet", :default => false)

        def execute
          require 'resque/scheduler'

          if background?
            abort "background requires ruby >= 1.9" unless Process.respond_to?('daemon')
            Process.daemon(true)
          end

          ::Resque::Scheduler.dynamic = dynamic_schedule?
          ::Resque::Scheduler.verbose = !quiet?
          ::Resque::Scheduler.run
        end
      end

      subcommand "run_webadmin", "forks a resque::scheduler process" do
        def execute
          `resque-web`
        end
      end

      subcommand "ps", "list running resque processes (using ps)" do
        def execute
          `ps aux`.split("\n").grep(/resque-/).each do |line|
            case line
              when /^(.*)(resque-.*)/
              psdata = $1.squeeze.split
              puts "Process #{psdata[1]}, started #{psdata[8]} : #{$2}"
            end
          end
        end
      end
    end
  end
end
