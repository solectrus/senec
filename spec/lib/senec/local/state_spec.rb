RSpec.describe Senec::Local::State do
  subject(:state) { described_class.new(connection:) }

  let(:senec_host) { ENV.fetch('SENEC_HOST', nil) }

  let(:connection) do
    Senec::Local::Connection.new(host: senec_host, schema: ENV.fetch('SENEC_SCHEMA'))
  end

  # Dummy response from the SENEC web interface JavaScript file
  def mock_response
    <<~JS
      something();

      var system_state_name = {
          0: "EXAMPLE 0",
          1: "EXAMPLE 1",
          2: "EXAMPLE 2",
          10:"EXAMPLE 10",
          11:"EXAMPLE 11",
          16:"EXAMPLE 16"
      };

      somethingElse();
    JS
  end

  describe '#names' do
    subject(:names) { state.names(language:) }

    let(:expected_hash) do
      {
        0 => 'EXAMPLE 0',
        1 => 'EXAMPLE 1',
        2 => 'EXAMPLE 2',
        10 => 'EXAMPLE 10',
        11 => 'EXAMPLE 11',
        16 => 'EXAMPLE 16'
      }
    end

    context 'when language is :en' do
      let(:language) { :en }

      before do
        stub_request(:any, "https://#{senec_host}/js/EN-en.js").to_return(body: mock_response)
      end

      it { is_expected.to eq(expected_hash) }
    end

    context 'when language is :de' do
      let(:language) { :de }

      before do
        stub_request(:any, "https://#{senec_host}/js/DE-de.js").to_return(body: mock_response)
      end

      it { is_expected.to eq(expected_hash) }
    end

    context 'when language is :it' do
      let(:language) { :it }

      before do
        stub_request(:any, "https://#{senec_host}/js/IT-it.js").to_return(body: mock_response)
      end

      it { is_expected.to eq(expected_hash) }
    end

    context 'when language is invalid' do
      let(:language) { :xyz }

      it 'does not make a request' do
        expect { names }.to raise_error(Senec::Local::Error, 'Language xyz not supported')
      end
    end
  end
end
