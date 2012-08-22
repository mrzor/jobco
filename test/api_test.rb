require 'test_helper'

describe "JobCo API" do
  include PerformJob

  it "can enqueue" do
    assert JobCo.enqueue(BasicSample)
  end

  # it "can enqueue_in" do
  #   # assert JobCo::API::enqueue_in(BasicSample, XXX)
  # end

  # it "can enqueue_at" do
  #   # assert JobCo::API::enqueue_at(BasicSample, XXX)
  # end

  # it "can schedule" do
  # 	# assert JobCo::API::schedule(BasicSample, XXX)
  # end
end