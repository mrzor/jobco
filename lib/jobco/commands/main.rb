require "jobco/commands/resque"
require "jobco/commands/jobs"

module JobCo
  module Commands
    class Main < Clamp::Command
      subcommand "resque", "control resque, clamp style", Resque
      subcommand "jobs", "jobs subcommand", Jobs
    end
  end
end
