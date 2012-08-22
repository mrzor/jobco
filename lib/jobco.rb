class Redis # :nodoc:
  # FIXME:  instance_eval this when required, like a true hero.
  class Namespace # :nodoc:
    attr_reader :redis
  end
end

# XXX: move this where required, probably in the jobfile surrounding logic.
def _jobco_path *x # :nodoc:
  File::join(File::dirname(__FILE__), "jobco", *x)
end

require "resque"

# JobCo is a Resque distribution.
#
# It wraps Resque, alongside the +JobWithStatus+ and +Scheduler+ plugins,
# into one easy to use package.
#
# Check out the README if you haven't done so already.
#
# === What do I code with JobCo ?
#
# * Job definition : inherit from JobCo::Job and implement perform()
# * Job manipulation : JobCo::API
# * Job introspection : JobCo::Jobs (Useful if you wish to write your own logic around 'job control' - quite likely, right?)
module JobCo
  require "jobco/api"
  require "jobco/jobs"
  require "jobco/jobfile"
  # XXX: require jobco deps here and be done with it
  self.extend(JobCo::API)

  # Minimal JobCo initialization routine
  # It will not require the ruby files holding your job code (see #boot_and_load to do that).
  #
  # It's well suited as a JobCo Rails initializer provided Rails can load your job code.
  # One easy way for Rails to find your job ruby files is to put then under 'app/jobs'.
  #
  # Exemple:
  #    JobCo::boot # inside config/initializers/jobco.rb
  #
  def self.boot filename = Jobfile::find
    Jobfile::evaluate filename # populate JobCo::Config

    # assert Resque.redis.is_a?(Redis)
  end

  # General purpose JobCo initialization routine.
  #
  # Call this once if using JobCo 'bare ruby' style
  # Remember that job files can only be loaded once unless dark magic is used.
  #
  # See implementation for yourself.
  def self.boot_and_load filename = Jobfile::find
    JobCo::boot(filename)
    JobCo::Jobs::load_files
  end

  # JobCo environment
  #
  # Usually one of the "development", "test", "production" strings
  # Take its value from environment, using the first variable from JOBCO_ENV, RAILS_ENV or RACK_ENV
  # If none of the above variables are found, it defaults to "development" 
  def self.env
    @@env ||= ENV["JOBCO_ENV"] || ENV["RAILS_ENV"] || ENV["RACK_ENV"] || "development"
    @@env
  end

  # JobCo environment setter.
  #
  # Use this to manually force an environment (in Jobfile)
  # You should probably use the environment variables rather than this.
  def self.env= env
    @@env = env
  end

  def self.redis # :nodoc:
    @@redis ||= Redis::Namespace.new("jobco", :redis => ::Resque.redis.redis)
  end
end

# XXX ?
require "jobco/resque_worker_hooks"
require "jobco-plugins"