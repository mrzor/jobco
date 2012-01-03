module JobCo
  # JobCo::Jobs API is what you use to write administration tools or automation
  # about your jobs.
  #
  # See those functions in use in the jobco/commands/* files.
  #
  # XXX move this in JobCo::API module
  class Jobs
    def self.select_job_class pattern
      c = self.available_jobs.select { |j| j.to_s.downcase.include?(pattern.downcase) }
      if c.size > 1
        fail "Different jobs match `#{pattern}': #{c.join(', ')}"
      elsif c.empty?
        fail "No jobs are matching `#{pattern}'. Use `jobs ls' command."
      end
      c.first
    end

    def self.available_jobs
      return @@available_jobs if defined?(@@available_jobs)
      jobs = []

      # 1) require any rb file in load path
      Config.job_load_path.each do |path|
        Dir[File::join(path, "*.rb")].each { |f| require f }
      end

      # 2) explore job package for jobco::job inheritors
      Config.job_modules.each do |mod|
        fail "#{mod} ain't a module" unless mod.is_a?(Module)
        jobs = jobs + mod.constants.map { |c| mod.const_get(c) }.select do |c|
          c.is_a?(Class) && c.ancestors.include?(::JobCo::Job)
        end
      end

      @@available_jobs = jobs
    end

    def self.load_available_jobs
      self.available_jobs
      nil
    end

    # JobCo specific
    # Returns last status entry for each job class
    # XXX: this belongs to JobCo::Jobs package
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
