require 'vcr'

VCR.configure do |config|
  config.hook_into :webmock
  config.hook_into :faraday
  config.cassette_library_dir = 'spec/support/cassettes'
  config.configure_rspec_metadata!

  %w[SENEC_USERNAME SENEC_PASSWORD SENEC_SYSTEM_ID].each do |env_var|
    config.filter_sensitive_data("<#{env_var}>") { ENV.fetch(env_var) }
  end

  config.filter_sensitive_data('<TOKEN>') do |interaction|
    if interaction.response.body.include?('token')
      JSON.parse(interaction.response.body)['token']
    elsif interaction.request.headers.include?('Authorization')
      interaction.request.headers['Authorization'].first
    end
  end

  %w[
    steuereinheitnummer
    gehaeusenummer
    strasse
    hausnummer
    postleitzahl
    ort
  ].each do |key|
    config.filter_sensitive_data("<#{key}>") do |interaction|
      if interaction.response.body.include?("\"#{key}\"")
        JSON.parse(interaction.response.body).first[key]
      end
    end
  end

  config.filter_sensitive_data('<SENEC_SYSTEM_ID>') do |interaction|
    if interaction.response.body.include?('id')
      JSON.parse(interaction.response.body).first['id']
    end
  end

  record_mode = ENV['VCR'] ? ENV['VCR'].to_sym : :once
  config.default_cassette_options = {
    record: record_mode,
    allow_playback_repeats: true
  }

  config.ignore_localhost = true
end
