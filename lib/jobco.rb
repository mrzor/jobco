def _jobco_path *x
  File::join(File::dirname(__FILE__), "jobco", *x)
end

Dir[_jobco_path("workers", "*rb")].each { |f| require f }
Dir[_jobco_path("orchestrators", "*rb")].each { |f| require f }
