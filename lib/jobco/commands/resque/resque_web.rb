module JobCo
  module Commands
    class ResqueWeb < Clamp::Command
      self.description = "Manage standalone resque-web server"

      subcommand "start", "guess what" do
        def execute
          require 'vegas'
          require "resque/server"
          br = lambda { |v| load _jobco_path("resque_web_conf.rb") }
          Vegas::Runner.new(::Resque::Server, 'resque-web', { :before_run => br })
        end
      end
    end
  end
end
