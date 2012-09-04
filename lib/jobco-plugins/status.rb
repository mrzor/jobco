require "resque/job"
require "jobco-plugins/status_entry"
require "jobco-plugins/status_hash"

module JobCo
  module Plugins
    # this module duplicates most of the functionality of resque-status
    #
    # it *does not* :
    # - include the kill subsystem of resque-status
    # - modify the resque API for job code (ie: use self.perform, enqueue as usual)

    module Status
      class << self
        # Use expire_after to have status data expire in redis automatically.
        # Default value is nil - meaning status data don't expire.
        #
        # Set the following in your #Jobfile to expire statuses:
        # `JobCo::Plugins::Status.expire_after = 86400 * 7 # one week`
        attr_accessor :expire_after

        # :nodoc:
        def included(base)
          base.extend(ClassMethods)
        end

        # high level status report
        def tick message = nil
          add_status "running", message
        end

        def at num, total, message
          add_status("running", {
            num: num,
            total: total,
            message: message
          })
        end

        def completed message = nil
          @finished = true
          add_status "completed", message
        end

        # low level status reporting
        def add_status status, message = nil
          @status ||= JobStatus.new(@@uuid)
          @status.add_status Time.now, status, message
          # puts "ADD #{@status.uuid} #{status}: #{message || "nil"}"
        end

      end

      ##
      # :nodoc:
      module ResqueHooks        
        def before_enqueue_jobco_status *args
          @status = JobStatus.new
          raise Resque::Job::ChangeArgs.new(args.unshift(@status.uuid))
        end

        def after_enqueue_jobco_status *args
          add_status "enqueued"
        end

        def before_perform_jobco_status *args
          @@uuid = args.shift
          add_status "perform"
          raise Resque::Job::ChangeArgs.new(args)
        end

        def after_perform_jobco_status *args
          # set default completion, if no manual completion was set
          add_status("completed (default)") unless @finished
        end

        def after_dequeue_jobco_status *args
          @@uuid = args.shift
          add_status "dequeued"
        end

        def on_failure_jobco_status exception, *args 
          @@uuid = args.shift unless defined?(@@uuid)
          message = {
            exception_string: exception.to_s,
            exception_backtrace: exception.backtrace
          }
          add_status "failed", message
        end
      end
    end
  end
end