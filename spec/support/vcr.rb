require 'vcr'

VCR.configure do |config|
  config.hook_into :webmock
  config.hook_into :faraday
  config.cassette_library_dir = 'spec/support/cassettes'
  config.configure_rspec_metadata!

  record_mode = ENV['VCR'] ? ENV['VCR'].to_sym : :once
  config.default_cassette_options = {
    record: record_mode,
    allow_playback_repeats: true
  }

  # Filter sensitive data from requests and responses
  config.filter_sensitive_data('FILTERED_EMAIL') { ENV['SENEC_USERNAME'] || 'mail@example.com' }
  config.filter_sensitive_data('FILTERED_PASSWORD') { ENV['SENEC_PASSWORD'] || 'topsecret' }

  # Use before_record hook to sanitize all sensitive data
  # :nocov:
  config.before_record do |interaction|
    # Filter URL-encoded credentials in request bodies
    if interaction.request.body
      interaction.request.body = interaction.request.body
                                            .gsub(/username=[^&]+&password=[^&]+/,
                                                  'username=FILTERED_EMAIL&password=FILTERED_PASSWORD',)
    end

    # Filter OAuth codes and tokens from request URIs
    interaction.request.uri = interaction.request.uri
                                         .gsub(/code=[^&]+/, 'code=FILTERED_CODE')
                                         .gsub(/state=[^&]+/, 'state=FILTERED_STATE')
                                         .gsub(/session_code=[^&]+/, 'session_code=FILTERED_SESSION_CODE')
                                         .gsub(/nonce=[^&]+/, 'nonce=FILTERED_NONCE')
                                         .gsub(/session_state=[^&]+/, 'session_state=FILTERED_SESSION_STATE')
                                         .gsub(/tab_id=[^&]+/, 'tab_id=FILTERED_TAB_ID')
                                         .gsub(/execution=[^&]+/, 'execution=FILTERED_EXECUTION')
                                         .gsub(/client_data=[^&]+/, 'client_data=FILTERED_CLIENT_DATA')

    # Filter cookies from request headers
    if interaction.request.headers['cookie']
      Array(interaction.request.headers['cookie']).map! do |cookie|
        cookie
          .gsub(/SESSION=[^;]+/, 'SESSION=FILTERED_SESSION')
          .gsub(/XSRF-TOKEN=[^;]+/, 'XSRF-TOKEN=FILTERED_TOKEN')
          .gsub(/AUTH_SESSION_ID=[^;]+/, 'AUTH_SESSION_ID=FILTERED_SESSION')
          .gsub(/KC_AUTH_SESSION_HASH=[^;]+/, 'KC_AUTH_SESSION_HASH=FILTERED_HASH')
          .gsub(/KC_RESTART=[^;]+/, 'KC_RESTART=FILTERED_RESTART')
          .gsub(/KEYCLOAK_IDENTITY=[^;]+/, 'KEYCLOAK_IDENTITY=FILTERED_IDENTITY')
          .gsub(/KEYCLOAK_SESSION=[^;]+/, 'KEYCLOAK_SESSION=FILTERED_SESSION')
          .gsub(/KEYCLOAK_LOCALE=[^;]+/, 'KEYCLOAK_LOCALE=FILTERED_LOCALE')
      end
    end

    # Filter session cookies and tokens from response headers
    if interaction.response.headers['set-cookie']
      Array(interaction.response.headers['set-cookie']).map! do |cookie|
        cookie
          .gsub(/SESSION=[^;]+/, 'SESSION=FILTERED_SESSION')
          .gsub(/XSRF-TOKEN=[^;]+/, 'XSRF-TOKEN=FILTERED_TOKEN')
          .gsub(/AUTH_SESSION_ID=[^;]+/, 'AUTH_SESSION_ID=FILTERED_SESSION')
          .gsub(/KC_AUTH_SESSION_HASH=[^;]+/, 'KC_AUTH_SESSION_HASH=FILTERED_HASH')
          .gsub(/KC_RESTART=[^;]+/, 'KC_RESTART=FILTERED_RESTART')
          .gsub(/KEYCLOAK_IDENTITY=[^;]+/, 'KEYCLOAK_IDENTITY=FILTERED_IDENTITY')
          .gsub(/KEYCLOAK_SESSION=[^;]+/, 'KEYCLOAK_SESSION=FILTERED_SESSION')
          .gsub(/KEYCLOAK_LOCALE=[^;]+/, 'KEYCLOAK_LOCALE=FILTERED_LOCALE')
      end
    end

    # Filter OAuth codes and tokens from Location headers
    if interaction.response.headers['location']
      Array(interaction.response.headers['location']).map! do |location|
        location
          .gsub(/code=[^&]+/, 'code=FILTERED_CODE')
          .gsub(/state=[^&]+/, 'state=FILTERED_STATE')
          .gsub(/session_code=[^&]+/, 'session_code=FILTERED_SESSION_CODE')
          .gsub(/nonce=[^&]+/, 'nonce=FILTERED_NONCE')
          .gsub(/session_state=[^&]+/, 'session_state=FILTERED_SESSION_STATE')
          .gsub(/tab_id=[^&]+/, 'tab_id=FILTERED_TAB_ID')
          .gsub(/execution=[^&]+/, 'execution=FILTERED_EXECUTION')
          .gsub(/client_data=[^&]+/, 'client_data=FILTERED_CLIENT_DATA')
      end
    end

    # Filter sensitive data from response bodies (forms, JavaScript, etc.)
    if interaction.response.body
      interaction.response.body =
        interaction.response.body
                   .gsub(/checkAuthSession\(\s*"[^"]+"\s*\)/, 'checkAuthSession("FILTERED_HASH")')
                   .gsub(/session_code=[^&"]+/, 'session_code=FILTERED_SESSION_CODE')
                   .gsub(/execution=[^&"]+/, 'execution=FILTERED_EXECUTION')
                   .gsub(/tab_id=[^&"]+/, 'tab_id=FILTERED_TAB_ID')
                   .gsub(/client_data=[^&"]+/, 'client_data=FILTERED_CLIENT_DATA')
                   # Filter HTML-encoded email addresses in form values
                   .then do |body|
                     if ENV['SENEC_USERNAME']
                       email = ENV['SENEC_USERNAME']
                       body.gsub(/#{Regexp.escape(email.gsub('@', '&#64;'))}/, 'FILTERED_EMAIL')
                           .gsub(/#{Regexp.escape(email.gsub('@', '%40'))}/, 'FILTERED_EMAIL')
                           .gsub(/#{Regexp.escape(email)}/, 'FILTERED_EMAIL')
                     else
                       body
                     end
                   end
                   # Filter serial numbers and device identifiers from JSON responses
                   .gsub(/"caseSerialNumber":"[^"]+"/, '"caseSerialNumber":"FILTERED_CASE_SERIAL"')
                   .gsub(/"controllerSerialNumber":\d+/, '"controllerSerialNumber":999999999')
    end
  end
  # :nocov:
end

# Disable VCR when a WebMock stub is created
# https://github.com/vcr/vcr/issues/146#issuecomment-573217860
RSpec.configure do |config|
  WebMock::API.prepend(Module.new do
    extend self
    # disable VCR when a WebMock stub is created
    # for clearer spec failure messaging
    def stub_request(*args)
      VCR.turn_off!
      super
    end
  end)

  config.before { VCR.turn_on! }
end
