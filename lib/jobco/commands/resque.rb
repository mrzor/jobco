require 'resque'
require 'clamp'

module JobCo
  module Commands
    class Resque < Clamp::Command
      subcommand "run_worker", "forks a worker in the background" do
        option(["-q", "--quiet"], :flag, "Be quiet", :default => false)
        option(["-i", "--interval"],
               "INTERVAL", "Interval at which ",
               :default => (ENV['INTERVAL'] || 5).to_i)
        option(["-b", "--background"], :flag,
               "XXX BACKGROUND DOC",
               :default => ENV['BACKGROUND'] || false)
        option(["-Q", "--queues"],
               "QUEUES", "Job queue(s) the worker is serving.",
               :default => (ENV['QUEUES'] || ENV['QUEUE'] || "*"))
        option(["-p", "--pidfile"],
               "PIDFILE", "XXX PIDFILE DOC",
               :default => ENV['PIDFILE'])
        option(["-k", "--kill"], :flag,
               "Use `resque` to kill any running worker",
               :default => false)

        def queues= v;  @queues = v.to_s.split(','); end

        def execute
          require 'jobco/jobs'
          require 'resque/worker'

          if kill?
            ids = `resque list`
            if ids != "None\n"
              ids.split("\n").map { |x| x.split(" ").first }.each do |id|
                STDOUT << "resque kill #{id}"
                `resque kill #{id}`
                STDOUT << "  ok (#{$?}).\n"
              end
            end
          end

          if background?
            abort "background requires ruby >= 1.9" unless Process.respond_to?('daemon')
            Process.daemon(true)
          end

          worker = ::Resque::Worker.new(queues)
          worker.verbose = !quiet?
          # worker.very_verbose = true
          worker.work(interval)
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
          Resque::Scheduler::dynamic = true

          if background?
            abort "background requires ruby >= 1.9" unless Process.respond_to?('daemon')
            Process.daemon(true)
          end

          ::Resque::Scheduler.dynamic = dynamic_schedule?
          ::Resque::Scheduler.verbose = !quiet?
          ::Resque::Scheduler.run
        end
      end

      subcommand "run_resque_web", "forks a resque::scheduler process" do
        def execute
          require 'vegas'
          require "resque/server"
          br = lambda { |v| load _jobco_path("resque_web_conf.rb") }
          Vegas::Runner.new(::Resque::Server, 'resque-web', { :before_run => br })
        end
      end

      subcommand "ps", "list running resque processes (using ps)" do
        def execute
          `ps aux`.split("\n").grep(/resque[-_]/).each do |line|
            case line
              when /^(.*)(resque[-_].*)$/
              psdata = $1.squeeze(" \t").split
              puts "Process #{psdata[1]}, started #{psdata[8]} : #{$2}"
            end
          end
        end
      end
    end
  end
end
