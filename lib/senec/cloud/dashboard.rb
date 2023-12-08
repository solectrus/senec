require_relative 'connection'

# Model for the Senec dashboard data.
#
# Example use:
#
# connection = Senec::Cloud::Connection.new(username: '...', password: '...')
#
# # Get the data of a specific system:
# Dashboard[connection].find('123456')
#
# # Get the data of the default system:
# Dashboard[connection].first
#
module Senec
  module Cloud
    class Dashboard
      class Finder
        def initialize(connection)
          @connection = connection
        end
        attr_reader :connection

        def find(system_id)
          Dashboard.new(connection:, system_id:).tap(&:load_data)
        end

        def first
          find(connection.default_system_id)
        end
      end

      def self.[](connection)
        Finder.new(connection)
      end

      def initialize(connection: nil, system_id: nil, data: nil)
        raise ArgumentError unless connection.nil? ^ data.nil?

        @connection = connection
        @system_id = system_id

        # Useful for testing only
        @data = data
      end

      def load_data
        raise 'Data already present!' if @data

        @system_id ||= default_system_id
        @data = fetch_data
      end

      attr_reader :system_id, :data

      private

      def default_system_id
        @connection.default_system_id
      end

      def get(path, params: nil)
        @connection.get(path, params:)
      end

      def fetch_data
        return unless system_id

        get("/v1/senec/systems/#{system_id}/dashboard")
      end
    end
  end
end
