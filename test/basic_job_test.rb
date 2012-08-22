require 'test_helper'

# XXX: this should be setup and teared down
load File.expand_path("../../samples/basic.rb", __FILE__)

describe "Basic JobCo Sample" do
  include PerformJob

  it "is registered in JobCo" do
    assert JobCo::Jobs.available_jobs.include?(BasicSample)
  end

  it "can be enqueued" do
    assert Resque.enqueue(BasicSample)
  end

  it "can be performed" do
    assert_equal true, perform_job(BasicSample), "basic job can be performed"    
  end
end