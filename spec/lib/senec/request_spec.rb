RSpec.describe Senec::Request do
  subject(:request) { described_class.new(host: host, state_names: state_names) }

  let(:state_names) { Hash.new { |hash, key| hash[key] = "Status for #{key}" } }

  context 'with a valid host', vcr: { cassette_name: 'request' } do
    let(:host) { 'senec' }

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

      it { is_expected.to eq('3824') }
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

  context 'when host does not exist', vcr: true do
    let(:host) { 'invalid-host' }

    it 'raises an error' do
      expect { request.house_power }.to raise_error(SocketError)
    end
  end

  context 'when host is present but does not respond accordingly', vcr: { cassette_name: 'request-error' } do
    let(:host) { 'example.com' }

    it 'raises an error' do
      expect { request.house_power }.to raise_error(Senec::Error, 'Not Found')
    end
  end
end
