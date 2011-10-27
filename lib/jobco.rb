class Redis
  class Namespace
    attr_reader :redis
  end
end

def _jobco_path *x
  File::join(File::dirname(__FILE__), "jobco", *x)
end
