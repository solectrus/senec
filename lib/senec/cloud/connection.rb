module Senec
  module Cloud
    class Connection
      def initialize(username:, password:, token: nil)
        @username = username
        @password = password
        @token = token
      end

      attr_reader :username, :password

      def authenticated?
        !token.nil?
      end

      def systems
        get('/v1/senec/systems')
      end

      def default_system_id
        raise Error.new('No systems found!', :not_found) if systems.nil?

        systems[0]['id']
      end

      def get(path, params: nil)
        return_body do
          connection.get(path, params, { authorization: token })
        end
      end

      def post(path, data)
        return_body do
          connection.post(path, data)
        end
      end

      def token
        @token ||= login['token']
      end

      private

      def login
        post('/v1/senec/login', { username:, password: })
      end

      def connection
        @connection ||=
          Faraday.new(url: 'https://app-gateway.prod.senec.dev') do |f|
            f.request :json
            f.response :json

            f.headers['User-Agent'] = "ruby-senec/#{Senec::VERSION}"

            f.adapter :net_http_persistent, pool_size: 5 do |http|
              # :nocov:
              http.idle_timeout = 120
              # :nocov:
            end
          end
      end

      def return_body(&)
        response = yield

        unless response.success?
          raise Error.new("Error #{response.status}", response.status)
        end

        response.body
      end
    end
  end
end
