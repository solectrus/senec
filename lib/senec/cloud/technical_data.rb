require_relative 'connection'

# Model for the Senec technical data.
#
# Example use:
#
# connection = Senec::Cloud::Connection.new(username: '...', password: '...')
#
# # Get the data of a specific system:
# TechnicalData[connection].find('123456')
#
# # Get the data of the default system:
# TechnicalData[connection].first
#
module Senec
  module Cloud
    class TechnicalData
      class Finder
        def initialize(connection)
          @connection = connection
        end
        attr_reader :connection

        def find(system_id)
          TechnicalData.new(connection:, system_id:).tap(&:load_data)
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

        @system_id ||= connection.default_system_id
        @data = fetch_data
      end

      attr_reader :system_id, :data

      private

      def get(path, params: nil)
        @connection.get(path, params:)
      end

      def fetch_data
        return unless system_id

        get("/v1/senec/systems/#{system_id}/technical-data")
      end
    end
  end
end
