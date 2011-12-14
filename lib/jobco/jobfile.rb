require "ostruct"

module JobCo
  Config = OpenStruct.new

  class Jobfile

    def self.evaluate filename = self.find
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

    def initialize filename
      abort "what is #{@@filename} anyway ? (ONE JOBFILE AT A TIME PLZ)" if defined?(@@filename)
      @@filename = filename
      Config.job_modules = []
      Config.job_load_path = []
    end

    def job_load_path dir
      Config.job_load_path << dir
      Dir[File::join(dir, "*.rb")].each { |f| require f }
    end

    def job_module modul
      Config.job_modules << modul
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
