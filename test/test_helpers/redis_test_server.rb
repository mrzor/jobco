#
# make sure we can run redis
#

if !system("which redis-server")
  abort "** can't find `redis-server` in your path`"
end

#
# start our own redis when the tests start,
# kill it when they end
#

at_exit do
  next if $!

  if defined?(MiniTest)
    exit_code = MiniTest::Unit.new.run(ARGV)
  else
    exit_code = Test::Unit::AutoRunner.run
  end

  processes = `ps -A -o pid,command | grep [r]edis-test`.split("\n")
  pids = processes.map { |process| process.split(" ")[0] }
  puts "Killing test redis server..."
  #{ }`rm -f #{dir}/dump.rdb #{dir}/dump-cluster.rdb`
  pids.each { |pid| Process.kill("KILL", pid.to_i) }
  exit exit_code
end

# if ENV.key? 'RESQUE_DISTRIBUTED'
#   require 'redis/distributed'
#   puts "Starting redis for testing at localhost:9736 and localhost:9737..."
#   `redis-server #{dir}/redis-test.conf`
#   `redis-server #{dir}/redis-test-cluster.conf`
#   r = Redis::Distributed.new(['redis://localhost:9736', 'redis://localhost:9737'])
#   Resque.redis = Redis::Namespace.new :resque, :redis => r
# else
  puts "Starting redis for testing at localhost:9736..."
  puts `redis-server #{File.expand_path("../redis-test.conf", __FILE__)}`
  unless $?.success?
    abort "Failure to start test redis-server"
  end

  Resque.redis = 'localhost:9736'
# end
