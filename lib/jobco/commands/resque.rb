require 'resque'
require 'clamp'

Dir[_jobco_path("commands", "resque", "*rb")].each { |f| require f }

module JobCo
  # This module commands runnable as `jobco resque _____` in the CLI
  #
  # The code is based on the original Resque rake tasks, but have been
  # bundled inside a clamp package with no direct code reuse (ie, the code
  # is partially duplicated).
  #
  # Efforts have been made to get the whole package monit compatible,
  # so that you don't have to write shellscripts and what not to wrap it around.
  #
  module Commands
    class Resque < Clamp::Command
      subcommand "worker", "forks a worker in the background", ResqueWorker

      subcommand "run_scheduler", "forks a resque::scheduler process" do
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

          require 'jobco/jobs'
          JobCo::Jobs::load_available_jobs

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
