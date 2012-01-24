require "jobco/commands/resque"
require "jobco/commands/jobs"

module JobCo # :nodoc:
  module Commands # :nodoc:
    class Main < Clamp::Command # :nodoc:
      subcommand "resque", "control resque, clamp style", Resque
      subcommand "jobs", "jobs subcommand", Jobs
    end
  end
end
