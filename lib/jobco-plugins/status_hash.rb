require "uuid"

module JobCo
  module Plugins
    # JobStatus is a handle for all statuses for a specific job UUID.
    #
    # It keeps track of all different status updates, sorted by timestamp.
    #
    # JobStatus does not cache, any operation will at least make one
    # redis operation.
    #
    # JobStatus was inspired by Resque::Plugins::Status::Hash
    class JobStatus
      include Resque::Helpers
      attr_reader :uuid

      def initialize(uuid = nil)
        @uuid = uuid || ::UUID.generate(:compact)
      end

      # returns a timestamp to status_entry hash for all status entries stored
      # returns an empty hash if there are no recorded status entries
      def statuses
        data = redis.zrevrange(key(:uuid, @uuid), 0, -1) || []
        data.map { |datum| decode(datum) }
      end

      def empty?
        redis.zcard(key(:uuid, @uuid)) == 0
      end

      # adds a new status entry
      def add_status(timestamp, status, message=nil)
        # creates a status entry
        timestamp = timestamp.to_i
        entry = StatusEntry.new(timestamp, status, message)

        # sets the status_entry in the redis status hash
        redis.zadd(key(:uuid, @uuid), timestamp, encode(entry.to_h))

        # set/reset expiration on status hash
        if Status.expire_after
          redis.expire(key(:uuid, @uuid), Status.expire_after)
        end

        # Add entry to index if necessary.
        # We only score using the creation timestamp this way.
        if redis.zscore(key(:uuid_index), @uuid).nil?
          redis.zadd(key(:uuid_index), timestamp, @uuid)
        end
      end

      # retrieves StatusHashes for every known UUID, sorted by timestamp
      # optionally accepts start/end timestamps
      def self.all(range_start = nil, range_end = nil)
        status_ids(range_start, range_end).inject({}) do |memo, indexed_uuid|
          job_status = JobStatus.new(indexed_uuid)

          # expired UUID hash, remove from index
          if (job_status.empty?)
            redis.zrem(key(:uuid_index), indexed_uuid)
          else
            memo[indexed_uuid] = job_status
          end

          memo
        end
      end

      # queries the StatusHash index and returns known uuids
      # optionally accepts start/end timestamps
      def self.status_ids(range_start = nil, range_end = nil)
        unless range_end && range_start
          # Because we want a reverse chronological order, we need to get a range starting
          # by the higest negative number.
          redis.zrevrange(key(:uuid_index), 0, -1) || []
        else
          # Because we want a reverse chronological order, we need to get a range starting
          # by the higest negative number. The ordering is transparent from the API user's
          # perspective so we need to convert the passed params
          (redis.zrevrange(key(:uuid_index), (range_start.abs), ((range_end || 1).abs)) || [])
        end
      end

      private

      def key *args
        "jobco_status:#{args.join(':')}"
      end

      def self.key *args
        "jobco_status:#{args.join(':')}"
      end

      def self.redis
        ::Resque.redis
      end
    end
  end
end

#     # Create a status, generating a new UUID, passing the message to the status
#     # Returns the UUID of the new status.
#     def self.create(uuid, *messages)
#       set(uuid, *messages)
#       redis.zadd(set_key, Time.now.to_i, uuid)
#       redis.zremrangebyscore(set_key, 0, Time.now.to_i - @expire_in) if @expire_in
#       uuid
#     end

#     # Get a status by UUID. Returns a Resque::Plugins::Status::Hash
#     def self.get(uuid)
#       val = redis.get(status_key(uuid))
#       val ? Resque::Plugins::Status::Hash.new(uuid, decode(val)) : nil
#     end

#     # set a status by UUID. <tt>messages</tt> can be any number of stirngs or hashes
#     # that are merged in order to create a single status.
#     def self.set(uuid, *messages)
#       val = Resque::Plugins::Status::Hash.new(uuid, *messages)
#       redis.set(status_key(uuid), encode(val))
#       if expire_in
#         redis.expire(status_key(uuid), expire_in)
#       end
#       val
#     end

#     # clear statuses from redis passing an optional range. See `statuses` for info
#     # about ranges
#     def self.clear(range_start = nil, range_end = nil)
#       status_ids(range_start, range_end).each do |id|
#         remove(id)
#       end
#     end
    
#     def self.clear_completed(range_start = nil, range_end = nil)
#       status_ids(range_start, range_end).select do |id|
#         get(id).completed?
#       end.each do |id|
#         remove(id)
#       end
#     end
    
#     def self.remove(uuid)
#       redis.del(status_key(uuid))
#       redis.zrem(set_key, uuid)
#     end
#     # returns a Redisk::Logger scoped to the UUID. Any options passed are passed
#     # to the logger initialization.
#     #
#     # Ensures that Redisk is logging to the same Redis connection as Resque.
#     def self.logger(uuid, options = {})
#       require 'redisk' unless defined?(Redisk)
#       Redisk.redis = redis
#       Redisk::Logger.new(logger_key(uuid), options)
#     end

#     def self.count
#       redis.zcard(set_key)
#     end

#     # Return <tt>num</tt> Resque::Plugins::Status::Hash objects in reverse chronological order.
#     # By default returns the entire set.
#     # @param [Numeric] range_start The optional starting range
#     # @param [Numeric] range_end The optional ending range
#     # @example retuning the last 20 statuses
#     #   Resque::Plugins::Status::Hash.statuses(0, 20)
#     def self.statuses(range_start = nil, range_end = nil)
#       status_ids(range_start, range_end).collect do |id|
#         get(id)
#       end.compact
#     end

#     # Return the <tt>num</tt> most recent status/job UUIDs in reverse chronological order.
#     def self.status_ids(range_start = nil, range_end = nil)
#       unless range_end && range_start
#         # Because we want a reverse chronological order, we need to get a range starting
#         # by the higest negative number.
#         redis.zrevrange(set_key, 0, -1) || []
#       else
#         # Because we want a reverse chronological order, we need to get a range starting
#         # by the higest negative number. The ordering is transparent from the API user's
#         # perspective so we need to convert the passed params
#         (redis.zrevrange(set_key, (range_start.abs), ((range_end || 1).abs)) || [])
#       end
#     end

#     # The time in seconds that jobs and statuses should expire from Redis (after
#     # the last time they are touched/updated)
# def self.expire_in
#   @expire_in
# end

#     # Set the <tt>expire_in</tt> time in seconds
#     def self.expire_in=(seconds)
#       @expire_in = seconds.nil? ? nil : seconds.to_i
#     end

#     def self.status_key(uuid)
#       "status:#{uuid}"
#     end

#     def self.set_key
#       "_statuses"
#     end

#     def self.kill_key
#       "_kill"
#     end

#     def self.logger_key(uuid)
#       "_log:#{uuid}"
#     end

#     def self.generate_uuid
#       require 'uuid' unless defined?(UUID)
#       UUID.generate(:compact)
#     end

#     def self.hash_accessor(name, options = {})
#       options[:default] ||= nil
#       coerce = options[:coerce] ? ".#{options[:coerce]}" : ""
#       module_eval <<-EOT
#       def #{name}
#         value = (self['#{name}'] ? self['#{name}']#{coerce} : #{options[:default].inspect})
#         yield value if block_given?
#         value
#       end

#       def #{name}=(value)
#         self['#{name}'] = value
#       end

#       def #{name}?
#         !!self['#{name}']
#       end
#       EOT
#     end

#     STATUSES = %w{queued working completed failed killed}.freeze

#     hash_accessor :uuid
#     hash_accessor :name
#     hash_accessor :status
#     hash_accessor :message
#     hash_accessor :time
#     hash_accessor :options

#     hash_accessor :num
#     hash_accessor :total

#     # Create a new Resque::Plugins::Status::Hash object. If multiple arguments are passed
#     # it is assumed the first argument is the UUID and the rest are status objects.
#     # All arguments are subsequentily merged in order. Strings are assumed to
#     # be messages.
#     def initialize(uuid=nil, *args)
#       super nil
#       base_status = {
#         'time' => Time.now.to_i,
#         'status' => 'queued'
#       }
#       base_status['uuid'] = args.shift if args.length > 1
#       status_hash = args.inject(base_status) do |final, m|
#         m = {'message' => m} if m.is_a?(String)
#         final.merge(m || {})
#       end
#       self.replace(status_hash)
#     end

#     # calculate the % completion of the job based on <tt>status</tt>, <tt>num</tt>
#     # and <tt>total</tt>
#     def pct_complete
#       case status
#       when 'completed' then 100
#       when 'queued' then 0
#       else
#         t = (total == 0 || total.nil?) ? 1 : total
#         (((num || 0).to_f / t.to_f) * 100).to_i
#       end
#     end

#     # Return the time of the status initialization. If set returns a <tt>Time</tt>
#     # object, otherwise returns nil
#     def time
#       time? ? Time.at(self['time']) : nil
#     end

#     STATUSES.each do |status|
#       define_method("#{status}?") do
#         self['status'] === status
#       end
#     end

#     def to_json(*args)
#       json
#     end

#     # Return a JSON representation of the current object.
#     def json
#       h = self.dup
#       h['pct_complete'] = pct_complete
#       self.class.encode(h)
#     end

#     def inspect
#       "#<JobCo::StatusHash #{super}>"
#     end
#   end
# end