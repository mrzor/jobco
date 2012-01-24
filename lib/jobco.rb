class Redis # :nodoc:
  # FIXME:  instance_eval this when required, like a true hero.
  class Namespace # :nodoc:
    attr_reader :redis
  end
end

# XXX: move this where required, afaik in the jobfile surrounding logic.
def _jobco_path *x # :nodoc:
  File::join(File::dirname(__FILE__), "jobco", *x)
end

# JobCo is a Resque distribution.
#
# It wraps Resque, alongside the +JobWithStatus+ and +Scheduler+ plugins,
# into one easy to use package.
#
# === What does this mean ?
#
# For your job running projects, this translates to :
#
# * A +Jobfile+, generally project-wide, to help you define and configure
#   your jobs in a single file.
#
# * The +jobco+ command line tool:
#   * Wraps Resque process management (see <tt>jobco resque --help</tt> subcommands)
#   * Allows trivial job control (see <tt>jobco jobs --help</tt> subcommands)
#
# * The <tt>JobCo::*</tt> Ruby library, that provide useful primitives for writing and
#   controlling jobs.
#
#
# === What do I get - compared to rolling out my own stack ?
#
# Several things !
#
# * Sensible development/production defaults
# * Unified, (somewhat) documented class to inherit from : JobCo::Job
# * Job introspection routines (JobCo::Jobs) - Useful for custom 'job control' tools
# * Coherent job manipulation routines (JobCo::API)

module JobCo
  require "jobco/api"
  require "jobco/jobs"
  require "jobco/jobfile"
  self.extend(JobCo::API)

  # You want to call this once in your application.
  # It's perfectly fine for a jobco Rails initializer.
  #
  # If you would like JobCo to load code located in your
  # <tt>job_load_path</tt> (see Jobfile), see JobCo::Jobs::require_files
  # 
  def self.boot filename = Jobfile::find
    Jobfile::evaluate filename # populate JobCo::Config

    resque_redis = Config.resque_redis
    if resque_redis
      if resque_redis.is_a?(String)
        Resque.redis = resque_redis
      elsif resque_redis.is_a?(Hash)
        Resque.redis = Redis.new(resque_redis)
      elsif resque_redis == :default
      else
        fail "invalid 'resque_redis' jobconf : `#{resque_redis}`"
      end
    else
      fail "Jobfile: `jobconf 'resque_redis'` is mandatory."
    end
  end

  def self.redis # :nodoc:
    @@redis ||= Redis::Namespace.new("jobco", :redis => ::Resque.redis.redis)
  end
end
