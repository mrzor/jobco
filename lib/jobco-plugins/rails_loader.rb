module JobCo
  module Plugins
    ##
    # JobCo::Plugins::RailsLoader helps you access your Rails-dependant types,
    # such as your models. 
    #
    #     class MyJob
    #       include JobCo::Plugins::Base
    #       include JobCo::Plugins::RailsLoader
    #       
    #       def self.perform
    #         # whatever, using MyModel or MyMailer or what have you
    #       end
    #     end
    #
    # Using RailsLoader requires you to edit your Jobfile appropriately.
    # Read on for the available static properties.
    module RailsLoader
      class << self
        # Controls the rails loading behavior.
        # Accepts either the :once or :each_time symbol
        #
        # Canonical use case:
        #
        #     # In Jobfile
        #     case JobCo::env
        #       when "development"
        #         JobCo::Plugins::RailsLoader.mode = :each_time
        #    
        #       when "production"
        #         JobCo::Plugins::RailsLoder.mode = :once
        #
        #     end
        attr_accessor :rails_load_mode

        # path to your rails application environment.rb file
        # nil = ./config/environment.rb relative to Jobfile location
        attr_accessor :rails_environment_path

        # load rails before each perform if appropriate
        # @private
        def before_perform_jobco_rails_loader(*args)
          self.jobco_rails_load if self.rails_load_mode == :each_time
        end

        private

        def jobco_rails_load
          path = self.rails_environment_path || Jobfile.relative_path("config", "environment.rb")
          unless File.exists?(path)
            fail "where is rails ? file '#{path}' not found"
          end

          require path
          Rails.application.eager_load!
        end
      end
    end
  end
end

Resque.before_first_fork do
  # load rails once if appropriate
  if JobCo::Plugins::RailsLoader.rails_load_mode == :once
    JobCo::Plugins::RailsLoader.jobco_rails_load
  end
end