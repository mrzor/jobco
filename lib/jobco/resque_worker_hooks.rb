# this file is included late by jobco.rb
# it sets up stuff to happen before_first_fork, and then after_fork

Resque.before_first_fork do
	# load job code once if appropriate
  if JobCo::Config.job_load_mode == :once
    JobCo::Jobs.load_files
  end
end

Resque.after_fork do
	# load job code each time if appropriate
  if JobCo::Config.job_load_mode == :each_time
    JobCo::Jobs.load_files
  end
end