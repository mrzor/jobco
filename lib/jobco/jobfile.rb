require "ostruct"

module JobCo
  Config = OpenStruct.new

  class Jobfile
    def self.evaluate filename = self.find
      fail "jobfile not found" unless filename and File.exists?(filename)
      builder = new
      builder.instance_eval(File.read(filename), filename, 1)
    end

    def self.find dir = Dir.pwd
      p = File::join(dir, "Jobfile")
      return p if File.exists?(p)
      return nil if dir == "/"
      self.find File::expand_path(File::join(dir, ".."))
    end

    def initialize
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
