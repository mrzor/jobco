# XXX: instance_eval this when required, like a true hero.
class Redis
  class Namespace
    attr_reader :redis
  end
end

# XXX: move this where required, afaik in the jobfile surrounding logic.
def _jobco_path *x
  File::join(File::dirname(__FILE__), "jobco", *x)
end

# This is what belongs in this file, and it's not much.
module JobCo
  require "jobco/api"
  require "jobco/jobs"
  self.extend(JobCo::API)

  require "jobco/jobfile"
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

    # do not load available jobs automatically
  end

  def self.redis
    @@redis ||= Redis::Namespace.new("jobco", :redis => ::Resque.redis.redis)
  end
end
