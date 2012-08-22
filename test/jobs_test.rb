require 'test_helper'

describe "JobCo::Jobs API" do

  SampleDirectory = File.expand_path("../../samples", __FILE__)
  JJ = JobCo::Jobs

  before do
    JJ.unload_jobs
    JJ.load_files([SampleDirectory])
  end

  it "can 'load' a bunch of ruby files" do
    available_jobs = JJ.available_jobs
    refute available_jobs.empty?    
    assert available_jobs.include?(BasicSample)
    assert available_jobs.include?(StatusSample)
  end

  it "can unload job code" do
    refute JJ.available_jobs.empty?
    JJ.unload_jobs
    assert JJ.available_jobs.empty?
  end

  it "can 'unload' then 'load'" do
    refute JJ.available_jobs.empty?
    JJ.unload_jobs
    assert JJ.available_jobs.empty?
    JJ.load_files([SampleDirectory])
    refute JJ.available_jobs.empty?
  end
end