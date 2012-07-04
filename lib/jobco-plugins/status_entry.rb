module JobCo
  module Plugins
    class StatusEntry
      attr_reader :timestamp, :status, :message

      def initialize(timestamp, status, message)
        @timestamp, @status, @message = timestamp, status, message
      end

      def time
        Time.at(@timestamp).utc
      end

      def to_h
        {
          timestamp: timestamp,
          status: status,
          message: message
        }
      end
    end
  end
end