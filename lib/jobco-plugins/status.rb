require "resque/job"
require "jobco-plugins/status_entry"
require "jobco-plugins/status_hash"

module JobCo
  module Plugins
    # this module duplicates a subset of the functionality of resque-status
    # (and is very much in flux/edge)
    #
    # it *does not* :
    # - include the kill subsystem of resque-status
    # - modify the resque API for job code (ie: use self.perform, enqueue as usual)
    #
    module Status
      class << self
        # Use expire_after to have status data expire in redis automatically.
        # Default value is nil - meaning status data don't expire.
        #
        #     # In Jobfile
        #     JobCo::Plugins::Status.expire_after = 86400 * 7 # one week
        #
        attr_accessor :expire_after

        # the day a resque process will run more than one job at a time will see
        # this code go horribly wrong.
        #
        # dont mess with this
        # @private
        attr_accessor :uuid

        # used internally by the ResqueHooks. it stinks anyways.
        # dont use that.
        # @private
        def with_uuid temporary_uuid, &blk
          old_uuid = uuid
          blk.call
          uuid = old_uuid
        end

        # low level status reporting
        def add_status status, message = nil
          @status ||= JobStatus.new(Status.uuid)
          @status.add_status Time.now, status, message
          # puts "ADD #{@status.uuid} #{status}: #{message || "nil"}"
        end

        # this is part of the trick to mass hide all the resque hooks from the doc
        # @private
        def included(base)
          base.extend(Helpers)
          base.extend(ResqueHooks)
        end
      end

      # the functions contained in JobCo::Plugins::Status::Helpers
      # are available to use from your self.perform code
      module Helpers
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
          add_status "completed", message
        end

        # low level
        def add_status status, message = nil
          Status.add_status(status, message)
        end
      end

      # this is a trick to mass hide all the resque hooks in the doc
      # @private
      module ResqueHooks
        def before_enqueue_jobco_status *args
          @status = JobStatus.new
          raise Resque::Job::ChangeArgs.new(args.unshift(@status.uuid))
        end

        def after_enqueue_jobco_status *args
          Status.with_uuid(args.shift) do
            Status.add_status "enqueued"
          end
        end

        def before_perform_jobco_status *args
          Status.uuid = args.shift
          Status.add_status "perform"
          raise Resque::Job::ChangeArgs.new(args)
        end

        def after_perform_jobco_status *args
          Status.uuid = nil
          # set default completion, if no manual completion was set
          # add_status("completed (default)") unless @finished
        end

        def after_dequeue_jobco_status *args
          Status.with_uuid(args.shift) do
            Status.add_status "dequeued"
          end
        end

        def on_failure_jobco_status exception, *args
          message = {
            exception_string: exception.to_s,
            exception_backtrace: exception.backtrace
          }

          Status.with_uuid(args.shift) do
            Status.add_status "failed", message
          end
        end
      end
    end

    # used internally for some dark meta reasons
    # (magic anonymous types are fun only for a while)
    # @private
    class StatusProxy
      include JobCo::Plugins::Status
    end
  end
end