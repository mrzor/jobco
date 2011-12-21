module JobCo
  module Commands
    class ResqueWorker < Clamp::Command
      self.description = "Manage worker processes"

      subcommand "list", "list workers known to Resque" do
        def execute
          # this is a duplicated from bin/resque
          if ::Resque.workers.any?
            ::Resque.workers.each do |worker|
              puts "#{worker} (#{worker.state})"
            end
          else
            puts "None"
          end
        end
      end

      subcommand "stop", "guess what?" do
        self.description = <<EODOC
Stop Worker processes.

Default (PID file based, monit style): Send SIGQUIT and return
Resque (Resque Worker ID bases) (--compat): Behaves like 'resque kill [worker_id]'
EODOC

        option(["-p", "--pidfile"],
               "PID_FILE", "XXX PIDFILE DOC",
               :default => ENV['PIDFILE'])
        option(["-c", "--compat"],
               :flag, "`resque` compatibility mode: ID must be resque-style worker id (host:pid:queues)",
               :default => false)

        parameter "[ID]", "unique identifier for the worker",
                  :default => '1', :attribute_name => :id

        def execute
          if compat?
            Resque.remove_worker(id)
            puts "** removed #{id}"
          else
            pid_file ||= "/tmp/jobco-#{`whoami`.strip}/worker_#{id}.pid"
            abort "PID file #{pid_file} not found" unless File.exists?(pid_file)
            pid = File.read(pid_file).to_i
            `kill -QUIT #{pid} 2>&1`
          end
        end
      end

      # DOC: default verbosity level is Resque "verbose"
      #      use --quiet to get to Resque default verbosity level
      #      --quiet is not --silent, and --silent is not implemented.
      #
      # XXX: support custom rails env
      #      support atexit() style pidfile removal
      subcommand "start", "guess what?" do
        option(["-q", "--quiet"], :flag, "Be quiet", :default => false)
        option(["-v", "--verbose"], :flag, "Be verbose", :default => false)
        option(["-i", "--interval"],
               "INTERVAL", "Interval at which ",
               :default => (ENV['INTERVAL'] || 5).to_i)
        option(["-b", "--background"], :flag,
               "XXX BACKGROUND DOC",
               :default => ENV['BACKGROUND'] || false)
        option(["-Q", "--queues"],
               "QUEUES", "Job queue(s) the worker is serving.",
               :default => (ENV['QUEUES'] || ENV['QUEUE'] || "*"))
        option(["-p", "--pidfile"],
               "PID_FILE", "XXX PIDFILE DOC",
               :default => ENV['PIDFILE'])


        parameter "[ID]", "unique identifier for the worker",
                  :default => '1', :attribute_name => :id

        def queues= v;  @queues = v.to_s.split(','); end

        def execute
          require 'resque/worker'

          require 'jobco/jobs'
          JobCo::Jobs::load_available_jobs

          # `once` means before forking worker sub processes
          # xxx: answer question 'can this be done after backgrounding?'
          JobCo::Job::require_rails if JobCo::Config.require_rails == :once

          if background?
            abort "background requires ruby >= 1.9" unless Process.respond_to?('daemon')
            Process.daemon(true)
          end

          worker = ::Resque::Worker.new(queues)
          worker.verbose = !quiet?
          worker.very_verbose = verbose?

          pid_file ||= "/tmp/jobco-#{`whoami`.strip}/worker_#{id}.pid"

          # create pid directory if necessary
          pid_dir = File.dirname(pid_file)
          Dir.mkdir(pid_dir) unless Dir.exists?(pid_dir)

          # write pid file if not exists
          File.open(pid_file, 'w') { |f| f << worker.pid }

          # XXX: at exit, remove pid_file

          # Finally, work.
          worker.work(interval)

          # If we shall even reach this, we shall remove the PID file.
          # Don't SIGKILL me you insensitive bastard.
          File.unlink(pid_file) if File.exists?(pid_file)
        end
      end
    end
  end
end

