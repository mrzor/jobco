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
require "jobco/api"
module JobCo
  def self.redis
    @@redis ||= Redis::Namespace.new("jobco", :redis => ::Resque.redis.redis)
  end

  self.extend(JobCo::API)
end
