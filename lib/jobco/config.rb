module JobCo
  module Config
  	class << self
  		# an array of pathes, where the code for jobs is located
  		attr_accessor :job_load_path

  		# when should the job code be loaded by jobco ?
  		# valid options:
  		# - :once (before fork, good for production)
  		# - :each_time (after fork, good for development)
  		attr_accessor :job_load_mode
		end
	end
end
