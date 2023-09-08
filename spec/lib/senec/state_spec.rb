RSpec.describe Senec::State do
  subject(:request) do
    described_class.new(connection:).tap do |state|
      allow(state).to receive(:response).and_return(mock_response)
    end
  end

  let(:connection) { Senec::Connection.new(host: 'senec', schema: 'https') }

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
    subject { request.names }

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

    it { is_expected.to eq(expected_hash) }
  end
end
