module JobCo
  module Plugins
    ##
    # JobCo::Plugins::Base is what you include in your job classes.
    #
    #     class MyJob
    #       include JobCo::Plugins::Base
    #       
    #       def self.perform
    #         # whatever
    #       end
    #     end
    #
    # Doing the include ensures that JobCo will be able to find your job
    # back in commands such as `jobco jobs ls`
    module Base
      class << self
        # XXX: register_available_job is a no-op
        # @private
        def included(base)
          ::JobCo::Jobs.register_available_job(base)
          # base.extend(ClassMethods)
        end

      # module ClassMethods

        # XXX: this is mostly useless
        # @private
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