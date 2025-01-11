require_relative 'connection'

# Model for the Senec dashboard data.
#
# Example use:
#
# connection = Senec::Cloud::Connection.new(username: '...', password: '...')
#
# # Get the data of a specific system:
# Dashboard[connection].find('123456').data
#
# # Get the data of the default system:
# Dashboard[connection].first.data
#
# By default, it returns v1 data. To get v2 data, use:
#
# Dashboard[connection].find('123456').data(version: 'v2')
# or
# Dashboard[connection].first.data(version: 'v2')
#
module Senec
  module Cloud
    class Dashboard
      AVAILABLE_VERSIONS = %w[v1 v2].freeze
      DEFAULT_VERSION = 'v1'.freeze

      class Finder
        def initialize(connection)
          @connection = connection
        end
        attr_reader :connection

        def find(system_id)
          Dashboard.new(connection:, system_id:)
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
        @data = {
          'v1' => data,
          'v2' => data
        }
      end

      def data(version: DEFAULT_VERSION)
        @data ||= {}
        @data[version] ||= fetch_data(version:)
      end

      attr_reader :system_id

      private

      def get(path, params: nil)
        @connection.get(path, params:)
      end

      def fetch_data(version:)
        raise ArgumentError unless AVAILABLE_VERSIONS.include?(version)
        return unless system_id

        get("/#{version}/senec/systems/#{system_id}/dashboard")
      end
    end
  end
end
