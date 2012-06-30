module JobCo
  #
  # === What is this ?
  #
  # The <tt>JobCo::Jobs</tt> package contains routines you can use to write
  # administration tools or automation about your jobs.
  #
  # The <tt>jobco jobs</tt> tool implementation might be useful as an example.
  #
  class Jobs
    @@available_jobs = []

    class NoSuchJob < Exception
    end

    # load ruby code stored in job load pathes
    # see the +job_load_path+ directive in Jobfile.
    def self.require_files
      Config.job_load_path.each do |path|
        Dir[File::join(path, "*.rb")].each { |f| require f }
      end if Config.job_load_path
    end

    # returns an array of Class objects, each one being a JobCo::Job descendant.
    def self.available_jobs
      @@available_jobs.dup.freeze
    end

    # called by JobCo::Job::inherited()
    def self.register_available_job job_class # :nodoc:
      @@available_jobs << job_class unless @@available_jobs.include?(job_class)
    end

    def self.select_job pattern
      c = available_jobs.select { |j| j.to_s.downcase.include?(pattern.downcase) }
      if c.size > 1
        raise NoSuchJob.new("Several jobs match `#{pattern}': #{c.join(', ')}")
      elsif c.empty?
        raise NoSuchJob.new("No jobs are matching `#{pattern}'.")
      end
      c.first
    end

    # JobCo specific
    # Returns last status entry for each job class
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
