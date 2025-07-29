require 'vcr'

def oauth_param_filters(*params)
  params.to_h do |param|
    [/#{param}=[^&"]+/, "#{param}=FILTERED_#{param.upcase}"]
  end
end

def cookie_filters(*names)
  names.to_h do |name|
    [/#{name}=[^;]+/, "#{name}=FILTERED_#{name.split('_').last}"]
  end
end

def json_string_filters(*fields)
  fields.to_h do |field|
    [/"#{field}":"[^"]+"/, "\"#{field}\":\"FILTERED_#{field.upcase}\""]
  end
end

def json_number_filters(fields)
  fields.to_h { |field, value| [/"#{field}":\d+/, "\"#{field}\":#{value}"] }
end

FILTERS = {
  oauth_params:
    oauth_param_filters(
      'code',
      'code_challenge',
      'code_verifier',
      'session_code',
      'session_state',
      'tab_id',
      'execution',
      'client_data',
    ),
  cookies:
    cookie_filters(
      'AUTH_SESSION_ID',
      'KC_AUTH_SESSION_HASH',
      'KC_RESTART',
      'KEYCLOAK_IDENTITY',
      'KEYCLOAK_SESSION',
      'KEYCLOAK_LOCALE',
    ),
  auth_tokens: {
    /Bearer [A-Za-z0-9._-]+/ => 'Bearer FILTERED_BEARER_TOKEN',
    %r{Basic [A-Za-z0-9+/=]+} => 'Basic FILTERED_BASIC_TOKEN',
    **json_string_filters('access_token', 'refresh_token', 'session_state')
  },
  uri_system_ids: {
    %r{/systems/\d+/} => '/systems/999999/'
  },
  personal_data: {
    /username=[^&]+&password=[^&]+/ =>
      'username=FILTERED_EMAIL&password=FILTERED_PASSWORD',
    /checkAuthSession\(\s*"[^"]+"\s*\)/ => 'checkAuthSession("FILTERED_HASH")',
    **json_string_filters(
      'caseSerialNumber',
      'controlUnitNumber',
      'caseNumber',
      'street',
      'houseNumber',
      'postalCode',
      'city',
      'productId',
      'postcode',
      'region',
      'website',
      'companyName',
      'serialNumber',
      'serial',
      'mainControllerSerial',
      'controllerId',
      'installationDateTime',
      'endDateTime',
      'phoneNumber',
      'email',
    ),
    **json_number_filters(
      'controllerSerialNumber' => 999_999_999,
      'id' => 999_999,
      'systemId' => 999_999,
    )
  }
}.freeze

def normalize_oauth_secrets(uri_string)
  uri_string
    .gsub(/code_challenge=[^&]+/, 'code_challenge=NORMALIZED')
    .gsub(/code_verifier=[^&]+/, 'code_verifier=NORMALIZED')
    .gsub(/code=[a-f0-9-]+/, 'code=NORMALIZED')
    .gsub(/session_code=[^&]+/, 'session_code=NORMALIZED')
    .gsub(/session_state=[^&]+/, 'session_state=NORMALIZED')
    .gsub(/tab_id=[^&]+/, 'tab_id=NORMALIZED')
    .gsub(/execution=[^&]+/, 'execution=NORMALIZED')
    .gsub(/client_data=[^&]+/, 'client_data=NORMALIZED')
end

def normalize_system_ids(uri_string)
  uri_string.gsub(%r{/systems/\d+/}, '/systems/999999/')
end

VCR.configure do |config|
  config.hook_into :webmock
  config.hook_into :faraday
  config.cassette_library_dir = 'spec/support/cassettes'
  config.configure_rspec_metadata!

  record_mode = ENV['VCR'] ? ENV['VCR'].to_sym : :once
  config.default_cassette_options = {
    record: record_mode,
    allow_playback_repeats: true,
    match_requests_on: %i[method oauth_uri],
    decode_compressed_response: true
  }

  # Custom matcher that normalizes dynamic OAuth secrets and system IDs
  config.register_request_matcher :oauth_uri do |request1, request2|
    uri1 = normalize_system_ids(normalize_oauth_secrets(request1.uri))
    uri2 = normalize_system_ids(normalize_oauth_secrets(request2.uri))
    uri1 == uri2
  end

  # Filter sensitive data from requests and responses
  config.filter_sensitive_data('FILTERED_EMAIL') do
    ENV.fetch('SENEC_USERNAME', nil)
  end
  config.filter_sensitive_data('FILTERED_PASSWORD') do
    ENV.fetch('SENEC_PASSWORD', nil)
  end
  config.filter_sensitive_data('[999999]') do
    system_id = ENV.fetch('SENEC_SYSTEM_ID', nil)
    system_id ? "[#{system_id}]" : nil
  end
  config.filter_sensitive_data('["999999"]') do
    system_id = ENV.fetch('SENEC_SYSTEM_ID', nil)
    system_id ? "[\"#{system_id}\"]" : nil
  end

  # Use before_record hook to sanitize all sensitive data
  # :nocov:
  config.before_record do |interaction|
    filter_request_data(interaction.request)
    filter_response_data(interaction.response)
  end

  def self.filter_request_data(request)
    if request.body
      request.body =
        apply_filters(request.body, :oauth_params, :personal_data)
    end
    request.uri = apply_filters(request.uri, :oauth_params, :uri_system_ids)
    apply_array_filters(request.headers['cookie'], :cookies)
    apply_array_filters(request.headers['Authorization'], :auth_tokens)
  end

  def self.filter_response_data(response)
    apply_array_filters(response.headers['set-cookie'], :cookies)
    apply_array_filters(response.headers['location'], :oauth_params)
    response.body = filter_response_body(response.body) if response.body
  end

  def self.filter_response_body(body)
    body = apply_filters(body, :oauth_params, :auth_tokens, :personal_data)
    filter_email_variants(body)
  end

  def self.filter_email_variants(body)
    return body unless (email = ENV.fetch('SENEC_USERNAME', nil))

    body
      .gsub(/#{Regexp.escape(email.gsub('@', '&#64;'))}/, 'FILTERED_EMAIL')
      .gsub(/#{Regexp.escape(email.gsub('@', '%40'))}/, 'FILTERED_EMAIL')
      .gsub(/#{Regexp.escape(email)}/, 'FILTERED_EMAIL')
  end

  def self.apply_filters(text, *filter_types)
    return text unless text

    filter_types.each do |type|
      FILTERS[type].each do |pattern, replacement|
        text = text.gsub(pattern, replacement)
      end
    end
    text
  end

  def self.apply_array_filters(array_data, *filter_types)
    return unless array_data

    Array(array_data).map! { |item| apply_filters(item, *filter_types) }
  end
  # :nocov:
end

# Disable VCR when a WebMock stub is created
# https://github.com/vcr/vcr/issues/146#issuecomment-573217860
RSpec.configure do |config|
  WebMock::API.prepend(
    Module.new do
      extend self

      # disable VCR when a WebMock stub is created
      # for clearer spec failure messaging
      def stub_request(*args)
        VCR.turn_off!
        super
      end
    end,
  )

  config.before { VCR.turn_on! }
end
