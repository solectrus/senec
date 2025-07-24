require 'faraday'
require 'json'

module Senec
  module Cloud
    BASE_URL = 'https://mein-senec.de'.freeze

    class Connection
      DEFAULT_USER_AGENT = "ruby-senec/#{Senec::VERSION} (+https://github.com/solectrus/senec)".freeze
      MAX_REDIRECTS = 10

      def initialize(username:, password:, user_agent: DEFAULT_USER_AGENT)
        @username = username
        @password = password
        @user_agent = user_agent
        @cookies = {}
      end

      attr_reader :username, :password, :user_agent, :cookies

      def authenticated?
        authenticate if cookies.empty?

        cookies.key?('sso.senec.com_KEYCLOAK_IDENTITY')
      end

      def authenticate
        response = request_with_redirects(Cloud::BASE_URL)

        # Find form with username and password inputs
        form_match = find_login_form(response.body)
        raise Error, 'Login form not found!' unless form_match

        # Perform the login request with the extracted form action URL
        form_action = form_match.gsub('&amp;', '&')
        request_with_redirects(
          form_action, {
            'username' => username,
            'password' => password
          },
        )
      end

      def simple_request(url)
        perform_request(url)
      end

      def request_with_redirects(url, data = nil)
        uri = URI(url)
        redirect_count = 0
        response = nil

        loop do
          response = perform_request(uri.to_s, data)
          store_cookies(response)

          break unless (300..399).cover?(response.status)

          location = response.headers['location']
          break unless location

          redirect_count += 1
          raise 'Too many redirects!' if redirect_count > MAX_REDIRECTS

          uri = location.start_with?('http') ? URI(location) : URI.join(uri, location)
          data = nil # Clear data after first request (no POST redirects)
        end

        response
      end

      private

      def find_login_form(html_body)
        # Find all forms and check if they contain both username and password inputs
        html_body.scan(%r{<form[^>]*action="([^"]+)"[^>]*>(.*?)</form>}m).each do |action, form_content|
          has_username = form_content.match(/input[^>]*name=["']username["'][^>]*/)
          has_password = form_content.match(/input[^>]*name=["']password["'][^>]*/)

          return action if has_username && has_password
        end

        # :nocov:
        nil
        # :nocov:
      end

      def faraday
        @faraday ||= Faraday.new do |f|
          f.adapter :net_http_persistent, pool_size: 1 do |http|
            # :nocov:
            http.idle_timeout = 400
            # :nocov:
          end
        end
      end

      def perform_request(url, data = nil)
        method = data ? :post : :get
        faraday.public_send(method, url) do |req|
          configure_request_headers(req)
          if method == :post
            req.body = URI.encode_www_form(data)
            req.headers['content-type'] = 'application/x-www-form-urlencoded'
          end
        end
      end

      def configure_request_headers(request)
        request.headers['user-agent'] = user_agent
        request.headers['connection'] = 'keep-alive'
        request.headers['cookie'] = cookies.values.join('; ') unless cookies.empty?
      end

      def store_cookies(response)
        host = URI(response.env.url).host
        cookie_header = response.headers['set-cookie']
        return unless cookie_header

        Array(cookie_header).each do |cookie_string|
          cookie_string.split(', ').each do |cookie|
            cookie_name = cookie.split('=').first
            cookie_value = cookie.split(';').first
            @cookies["#{host}_#{cookie_name}"] = cookie_value
          end
        end
      end
    end
  end
end
