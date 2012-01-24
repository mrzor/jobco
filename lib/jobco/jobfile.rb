require "ostruct"
require "jobco/config"

module JobCo
  # = Jobfile basics
  #
  # XXX
  # see sample
  #
  # = Job configuration
  # When it changed, you might want to reload your scheduler or rails app.
  #
  # = jobconf[] special keys
  #
  # `:require_rails` can be `:once` (worker spawner will load rails, then fork workers with rails loaded) or `:each_time` (each forked process will load rails independantly, useful in development)
  #
  # `:status_ttl` : Time (in seconds) during which job status are kept in redis. Nil for no expiry.
  #
  # = Jobfile class
  #
  # Jobfile class is of internal use to JobCo.
  #
  # While using JobCo as a library, you could mess with it at your own risk,
  # but it is not recommanded.
  class Jobfile

    def self.evaluate filename
      fail "jobfile not found" unless filename and File.exists?(filename)
      builder = new(filename)
      builder.instance_eval(File.read(filename), filename, 1)
    end

    def self.find dir = Dir.pwd
      p = File::join(dir, "Jobfile")
      return p if File.exists?(p)
      return nil if dir == "/"
      self.find File::expand_path(File::join(dir, ".."))
    end

    def self.relative_path *path
      File::join(File::dirname(@@filename), *path)
    end

    # this will happily overwrite any previously loaded Jobfile
    # there can only be one Jobfile loaded at a time :
    # weird combination of Jobfiles are unsupported atm.
    def initialize filename
      @@filename = filename
      Config.job_load_path = []
    end

    def job_load_path dir
      Config.job_load_path << dir
      Dir[File::join(dir, "*.rb")].each { |f| require f }
    end

    # @jobco_readonly is used so that configuration for env
    # different than current env is still interpreted and checked for errors
    # the following should be caught, in fact, in development environment.
    #
    # ex:
    # env :production do
    #   XXX_SYNTAX_ERROR_XXX
    # end
    def jobconf k, v
      return if @jobco_readonly
      Config.send("#{k}=", v)
    end

    def env env_name, &blk
      @jobco_readonly = true if (ENV["RACK_ENV"] || "development") != env_name.to_s
      blk.call
      @jobco_readonly = nil
    end
  end
end
