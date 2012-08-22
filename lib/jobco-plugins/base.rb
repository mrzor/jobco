module JobCo
  module Plugins
    # JobCo::Plugins::Base is what you include in your job classes.

    module Base
      def self.included(base)
        ::JobCo::Jobs.register_available_job(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def before_perform_jobco_base(*args)
        end

        def on_failure_jobco_base(exception, *args)
          puts "*** JobCo::Plugins::Base Exception Printer"
          puts "***\n" * 3
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