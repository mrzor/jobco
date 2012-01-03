require 'resque'
require 'clamp'

Dir[_jobco_path("commands", "resque", "*rb")].each { |f| require f }

module JobCo
  # This module commands runnable as `jobco resque _____` in the CLI
  #
  #
  # Efforts have been made to get the whole package monit compatible,
  # so that you don't have to write shellscripts and what not to wrap it around.
  #
  module Commands
    class Resque < Clamp::Command
      subcommand "worker", "worker process handling", ResqueWorker
      subcommand "scheduler", "scheduler process handling", ResqueScheduler
      subcommand "web", "resque web process handling", ResqueWeb

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
