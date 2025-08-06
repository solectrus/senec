require 'oauth2'
require 'rotp'

module Senec
  module Cloud
    CONFIG_URL =
      'https://sso.senec.com/realms/senec/.well-known/openid-configuration'.freeze

    CLIENT_ID = 'endcustomer-app-frontend'.freeze
    REDIRECT_URI = 'senec-app-auth://keycloak.prod'.freeze
    SCOPE = 'roles meinsenec'.freeze

    SYSTEMS_HOST = 'https://senec-app-systems-proxy.prod.senec.dev'.freeze
    MEASUREMENTS_HOST = 'https://senec-app-measurements-proxy.prod.senec.dev'.freeze
    WALLBOX_HOST = 'https://senec-app-wallbox-proxy.prod.senec.dev'.freeze

    class Connection
      DEFAULT_USER_AGENT = "ruby-senec/#{Senec::VERSION} (+https://github.com/solectrus/senec)".freeze

      def initialize(username:, password:, user_agent: DEFAULT_USER_AGENT, totp_uri: nil)
        @username = username
        @password = password
        @user_agent = user_agent
        @totp_uri = totp_uri
      end

      attr_reader :username, :password, :user_agent, :totp_uri

      def authenticate!
        code_verifier = SecureRandom.alphanumeric(43)
        digest = Digest::SHA256.digest(code_verifier)
        code_challenge = Base64.urlsafe_encode64(digest).delete('=')

        auth_url =
          oauth_client.auth_code.authorize_url(
            redirect_uri: REDIRECT_URI,
            scope: SCOPE,
            code_challenge:,
            code_challenge_method: 'S256',
          )

        # Manual HTTP needed for Keycloak cross-domain form handling
        login_form_url = fetch_login_form_url(auth_url)
        redirect_url = submit_credentials(login_form_url)
        authorization_code = extract_authorization_code(redirect_url)

        self.oauth_token =
          oauth_client.auth_code.get_token(
            authorization_code,
            redirect_uri: REDIRECT_URI,
            code_verifier:,
          )
      end

      def authenticated?
        !!oauth_token
      end

      def systems
        get "#{SYSTEMS_HOST}/v1/systems"
      end

      def system_details(system_id)
        get "#{SYSTEMS_HOST}/systems/#{system_id}/details"
      end

      def dashboard(system_id)
        get "#{MEASUREMENTS_HOST}/v1/systems/#{system_id}/dashboard"
      end

      def wallbox(system_id, wallbox_id)
        get "#{WALLBOX_HOST}/v1/systems/#{system_id}/wallboxes/#{wallbox_id}"
      end

      def wallbox_search(system_id)
        post "#{WALLBOX_HOST}/v1/systems/wallboxes/search", { systemIds: [system_id] }
      end

      private

      attr_accessor :oauth_token

      def fetch_login_form_url(auth_url)
        response = http_request(:get, auth_url)
        store_cookies(response) # Required for Keycloak CSRF protection
        extract_login_form_action_url(response.body) || raise('Login form not found')
      end

      def submit_credentials(form_url)
        credentials = { username:, password: }
        response = http_request(:post, form_url, data: credentials)

        if response.status == 200
          # Check if MFA is required
          if (totp_form_url = extract_totp_form_action_url(response.body))
            unless totp_uri
              raise 'MFA required but no TOTP URI provided'
            end

            response = submit_totp_form(totp_form_url)
          else
            # No OTP form found, assume login failed
            raise 'Login failed - invalid credentials or unexpected response'
          end
        end

        # Handle final redirect (same for both MFA and non-MFA flows)
        handle_redirect_response(response)
      end

      def submit_totp_form(form_url)
        totp = build_totp_from_uri(totp_uri)

        totp_data = { otp: totp.now }
        http_request(:post, form_url, data: totp_data)
      end

      def extract_authorization_code(redirect_url)
        raise 'Invalid redirect URL' unless redirect_url&.start_with?(REDIRECT_URI)

        uri = URI(redirect_url)
        params = URI.decode_www_form(uri.query).to_h

        params['code'] || raise('No authorization code found')
      end

      def extract_login_form_action_url(html)
        find_form_action_url(html) do |form|
          # Look for a form with username and password fields
          form.match(/name=["']?username["']?/i) &&
            form.match(/name=["']?password["']?/i)
        end
      end

      def extract_totp_form_action_url(html)
        find_form_action_url(html) do |form|
          # Look for a form with an OTP field
          form.match(/name=["']?otp["']?/i)
        end
      end

      def find_form_action_url(html)
        forms = html.scan(%r{<form[^>]*action="([^"]+)"[^>]*>(.*?)</form>}mi)

        forms.each do |action_url, form_content|
          return CGI.unescapeHTML(action_url) if yield(form_content)
        end

        nil
      end

      def build_totp_from_uri(uri_string)
        params = URI.decode_www_form(URI.parse(uri_string).query).to_h
        secret = params['secret'] || raise('Missing secret in TOTP URI')

        ROTP::TOTP.new(
          secret,
          digits: params['digits']&.to_i,
          period: params['period']&.to_i,
          algorithm: params['algorithm'],
        )
      end

      def handle_redirect_response(response)
        unless response.status == 302
          raise "Authentication failed, got unexpected response: #{response.status} #{response.body}"
        end

        response.headers['location'] || raise('No redirect location')
      end

      def ensure_token_valid
        authenticate! unless authenticated?
        return true unless oauth_token.expired?

        self.oauth_token = oauth_token.refresh!
        true
      rescue StandardError => e
        # :nocov:
        warn "Token refresh failed: #{e.message}"
        false
        # :nocov:
      end

      def get(url, default: nil)
        return default unless ensure_token_valid

        response = oauth_token.get(url)
        return default unless response.status == 200

        JSON.parse(response.body)
      rescue StandardError => e
        # :nocov:
        warn "API error: #{e.message}"
        default
        # :nocov:
      end

      def post(url, data, default: nil)
        return default unless ensure_token_valid

        response = oauth_token.post(
          url,
          body: data.to_json,
          headers: { 'Content-Type' => 'application/json' },
        )
        return default unless response.status == 200

        JSON.parse(response.body)
      rescue StandardError => e
        # :nocov:
        warn "API error: #{e.message}"
        default
        # :nocov:
      end

      def http_request(method, url, data: nil)
        Faraday
          .new
          .send(method, url) do |req|
            req.headers['user-agent'] = user_agent
            req.headers['connection'] = 'keep-alive'
            req.headers['cookie'] = cookie_string if cookies.any?
            req.body = URI.encode_www_form(data) if data
          end
      end

      def oauth_client
        @oauth_client ||=
          OAuth2::Client.new(
            CLIENT_ID,
            nil,
            site: openid_config['issuer'],
            authorize_url: openid_config['authorization_endpoint'],
            token_url: openid_config['token_endpoint'],
          )
      end

      def openid_config
        @openid_config ||= JSON.parse(http_request(:get, CONFIG_URL).body)
      rescue StandardError => e
        # :nocov:
        raise "Failed to load OpenID configuration: #{e.message}"
        # :nocov:
      end

      def cookies
        @cookies ||= {}
      end

      def cookie_string
        cookies.map { |k, v| "#{k}=#{v}" }.join('; ')
      end

      def store_cookies(response)
        set_cookie = response.headers['set-cookie']
        return unless set_cookie

        set_cookie
          .split(', ')
          .each do |cookie_header|
            name, value = cookie_header.split(';').first.split('=', 2)
            cookies[name] = value if name && value
          end
      end
    end
  end
end
