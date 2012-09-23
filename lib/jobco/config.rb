module JobCo
  ##
  # The Config module holds static properties that are important to JobCo.
  # You are encouraged to set those properties right from your Jobfile
  # See #Jobfile documentation for more general documentation about this.
  #
  # Some plugins might also have similar static properties.
  module Config
  	class << self
      #
  		# an array of pathes, where the code for jobs is located
      #
      # the following makes it so that if your Jobfile is in /my/stuff
      # it is expected that your job code is located in /my/stuff/app/jobs
      #
      #    # in Jobfile
      #    JobCo::Config.job_load_path = [File.expand_path('../app/jobs', __FILE__)]
      #
  		attr_accessor :job_load_path

  		# when should the job code be loaded by jobco ?
  		# valid options:
  		# - :once (before fork, good for production)
  		# - :each_time (after fork, good for development)
  		attr_accessor :job_load_mode

      # setting this to true requires jobco-plugins/rails_loader
      #
      # Checkout JobCo::Plugins::RailsLoader documentation.
      def support_rails= boolean
        require "jobco-plugins/rails_loader" if boolean == true
      end
		end
	end
end
