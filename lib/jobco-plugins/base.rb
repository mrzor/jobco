module JobCo
  module Plugins
    # JobCo::Plugins::Base is what you include in your job classes.

    module Base
      def self.included(base)
        ::JobCo::Jobs.register_available_job(base)
        base.extend(ClassMethods)
        puts "JobCo::Plugins::Base included in #{base}"
      end

      module ClassMethods
        def before_perform_test *args
        end

        def on_failure_test exception, *args
          puts "*" * 50
          puts exception
          puts "\nBacktrace:"
          puts exception.backtrace.join("\n")
          # require "pry"
          # binding.pry
        end
      end
    end
  end
end