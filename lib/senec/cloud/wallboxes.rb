require_relative 'connection'
require 'net/http'
require 'json'

# Model for the Senec wallboxes data.
#
# Example use:
#
# connection = Senec::Cloud::Connection.new(username: '...', password: '...')
#
# # Get the data of a specific system:
# Senec::Cloud::Wallboxes.new(connection:, system_id: 1).data
#
# # Get the data of the default system (system_id 0):
# Senec::Cloud::Wallboxes.new(connection:).data
#
module Senec
  module Cloud
    class Wallboxes
      PATH = '/endkunde/api/wallboxes'.freeze

      def initialize(connection: nil, system_id: 0)
        raise ArgumentError unless connection

        @connection = connection
        @system_id = system_id
      end

      attr_reader :connection, :system_id

      def data
        @data ||= fetch_data
      end

      private

      def fetch_data
        connection.authenticate unless connection.authenticated?

        uri = URI("#{Cloud::BASE_URL}#{PATH}")
        uri.query = URI.encode_www_form(anlageNummer: system_id)

        response = connection.simple_request(uri.to_s)
        JSON.parse(response.body)
      rescue JSON::ParserError
        # :nocov:
        raise Error, "Failed to parse response from #{PATH}"
        # :nocov:
      end
    end
  end
end
