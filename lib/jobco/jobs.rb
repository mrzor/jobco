module JobCo
  #
  # === What is this ?
  #
  # The <tt>JobCo::Jobs</tt> package contains routines you can use to write
  # administration tools or automation about your jobs.
  #
  # The <tt>JobCo::Commands::Jobs</tt> implementation for a take on those.
  #
  class Jobs
    @@available_jobs = []

    class NoSuchJob < Exception
    end

    # (internal)
    # load ruby code stored in job load pathes
    # see Config.job_load_path property documentation
    def self.load_files directories = nil # :nodoc:
      directories ||= [Config.job_load_path] if Config.job_load_path
      required_files = directories.inject({}) do |memo, dir|
        Dir[File::join(dir, "**/*.rb")].each { |f| memo[f] = load f }
        memo
      end
    end

    # returns an array of Class that include the JobCo::Plugin::Base
    # those should all be conforming Resque-style job classes.
    def self.available_jobs
      # @@available_jobs.dup.freeze
      scan_available_jobs
    end

    # (internal)
    # called by JobCo::Plugins::Base
    # XXX: Never needed again ?
    def self.register_available_job job_class # :nodoc:
      # @@available_jobs << job_class unless @@available_jobs.include?(job_class)
    end

    # (internal)
    # most useful for jobco tests
    def self.unload_jobs # :nodoc: 
      self.available_jobs.each do |klass|
        Object.send(:remove_const, klass.name.to_sym)
      end
    end

    # XXXperimental
    def self.scan_available_jobs # :nodoc:
      Object.constants.map do |cname|
        cvalue = Object.const_get(cname)
        if cvalue.is_a?(Class) && cvalue.ancestors.include?(JobCo::Plugins::Base)
          cvalue
        else
          nil
        end
      end.compact
    end

    # fuzzy matcher for jobs.
    # no result, or many results, raise a NoSuchJob exception
    # pattern is to be any subset of a job class. search is case insensitive.
    def self.select_job pattern
      c = available_jobs.select { |j| j.to_s.downcase.include?(pattern.downcase) }
      if c.size > 1
        raise NoSuchJob.new("Several jobs match `#{pattern}': #{c.join(', ')}")
      elsif c.empty?
        raise NoSuchJob.new("No jobs are matching `#{pattern}'.")
      end
      c.first
    end

    # Returns last status entry for each job class
    # XXX: this should be static to JobCo::Plugins::Status
    def self.status
      Jobs.available_jobs.inject([]) do |memo, job_class|
        last_uuid = JobCo::redis.hget("last_class_uuid", job_class)
        last_status = ::Resque::Status.get(last_uuid)

        memo << {
          klass: job_class,
          status: last_status,
          queue: 'xxx',
          schedule: ''
        }
      end
    end

  end
end
