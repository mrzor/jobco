require "jobco/commands/resque"
require "jobco/commands/jobs"

module JobCo
  module Commands # :nodoc:
    class Main < Clamp::Command # :nodoc:
      subcommand "resque", "control resque, clamp style", Resque
      subcommand "jobs", "jobs subcommand", Jobs

      # option ["-j", "--jobfile"], "JOBFILE", "Use a specific Jobfile (default: looks up for Jobfile in current dir or any parent)", :default => JobCo::Jobfile.find
    end
  end
end
