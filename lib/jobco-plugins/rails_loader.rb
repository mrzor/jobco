module JobCo
  module Plugins
    module RailsLoader
      class << self
        # :once / :each_time
        attr_accessor :rails_load_mode

        # path to your rails application environment.rb file
        # nil = ./config/environment.rb relative to Jobfile location
        attr_accessor :rails_environment_path

        def before_perform_jobco_rails_loader(*args)
          self.jobco_rails_load if self.rails_load_mode == :each_time
        end

        def jobco_rails_load
          path = self.rails_environment_path || Jobfile.relative_path("config", "environment.rb")
          unless File.exists?(path)
            fail "where is rails ? file '#{path}' not found"
          end

          require highway_to_rails
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