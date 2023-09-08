RSpec.describe Senec::Request do
  let(:state_names) { Hash.new { |hash, key| hash[key] = "Status for #{key}" } }

  context 'with a valid connection', vcr: { cassette_name: 'request' } do
    subject(:request) { described_class.new(connection:, state_names:) }

    let(:connection) { Senec::Connection.new(host: 'senec', schema: 'https') }

    describe '#house_power' do
      subject { request.house_power }

      it { is_expected.to be_a(Float) }
    end

    describe '#inverter_power' do
      subject { request.inverter_power }

      it { is_expected.to be_a(Float) }
    end

    describe '#mpp_power' do
      subject { request.mpp_power }

      it { is_expected.to all(be_a(Float)) }
    end

    describe '#bat_power' do
      subject { request.bat_power }

      it { is_expected.to be_a(Float) }
    end

    describe '#bat_fuel_charge' do
      subject { request.bat_fuel_charge }

      it { is_expected.to be_a(Float) }
    end

    describe '#bat_charge_current' do
      subject { request.bat_charge_current }

      it { is_expected.to be_a(Float) }
    end

    describe '#bat_voltage' do
      subject { request.bat_voltage }

      it { is_expected.to be_a(Float) }
    end

    describe '#grid_power' do
      subject { request.grid_power }

      it { is_expected.to be_a(Float) }
    end

    describe '#wallbox_charge_power' do
      subject { request.wallbox_charge_power }

      it { is_expected.to eq([0.0, 0.0, 0.0, 0.0]) }
    end

    describe '#case_temp' do
      subject { request.case_temp }

      it { is_expected.to be_a(Float) }
    end

    describe '#application_version' do
      subject { request.application_version }

      it { is_expected.to eq('0825') }
    end

    describe '#current_state' do
      subject { request.current_state }

      it { is_expected.to be_a(Integer) }
      it { is_expected.to be_between(0, 98) }
    end

    describe '#current_state_name' do
      subject { request.current_state_name }

      it { is_expected.to be_a(String) }
    end

    describe '#measure_time' do
      subject { request.measure_time }

      it { is_expected.to be_a(Integer) }
    end
  end

  context 'when host does not exist', vcr: { cassette_name: 'unknown-host' } do
    subject(:request) { described_class.new(connection:, state_names:) }

    let(:connection) { Senec::Connection.new(host: 'invalid-host', schema: 'http') }

    it 'raises an error' do
      expect { request.house_power }.to raise_error(Faraday::ConnectionFailed)
    end
  end

  context 'when schema mismatch', vcr: { cassette_name: 'schema-mismatch' } do
    subject(:request) { described_class.new(connection:, state_names:) }

    let(:connection) { Senec::Connection.new(host: 'senec', schema: 'http') }

    it 'raises an error' do
      expect { request.house_power }.to raise_error(Faraday::ConnectionFailed)
    end
  end

  context 'when host is present but does not respond accordingly', vcr: { cassette_name: 'request-error' } do
    subject(:request) { described_class.new(connection:, state_names:) }

    let(:connection) { Senec::Connection.new(host: 'example.com', schema: 'http') }

    it 'raises an error' do
      expect { request.house_power }.to raise_error(Senec::Error, '404')
    end
  end
end
