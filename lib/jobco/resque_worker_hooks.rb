# this file is included late by jobco.rb, after Jobfile have been run
# it sets up stuff to happen before_first_fork, and then after_fork

case JobCo::Config.job_load_mode

when :once
  Resque.before_first_fork do
    JobCo::Jobs.load_files
  end

when :each_time
  Resque.after_fork do
    JobCo::Jobs.load_files
  end

when :each_time_nofork
  Resque.before_perform do
    JobCo::Jobs.load_files
  end

  Resque.after_perform do
    JobCo::Jobs.unload_jobs
  end
else
  fail "JobCo::Config.job_load_mode is unset (must be set in Jobfile)"

end