RSpec.describe Senec::Request do
  subject(:request) { described_class.new(host: host, state_names: state_names) }

  let(:state_names) { { 56 => 'PEAK-SHAVING: WARTEN' } }

  context 'with a valid host', vcr: { cassette_name: 'request' } do
    let(:host) { 'senec' }

    describe '#house_power' do
      subject { request.house_power }

      it { is_expected.to eq(433.9) }
    end

    describe '#inverter_power' do
      subject { request.inverter_power }

      it { is_expected.to eq(1404.4) }
    end

    describe '#mpp_power' do
      subject { request.mpp_power }

      it { is_expected.to eq([705.9, 0.0, 698.5]) }
    end

    describe '#bat_power' do
      subject { request.bat_power }

      it { is_expected.to eq(89.1) }
    end

    describe '#bat_fuel_charge' do
      subject { request.bat_fuel_charge }

      it { is_expected.to eq(60.6) }
    end

    describe '#bat_charge_current' do
      subject { request.bat_charge_current }

      it { is_expected.to eq(1.7) }
    end

    describe '#bat_voltage' do
      subject { request.bat_voltage }

      it { is_expected.to eq(53.0) }
    end

    describe '#grid_power' do
      subject { request.grid_power }

      it { is_expected.to eq(-881.3) }
    end

    describe '#wallbox_charge_power' do
      subject { request.wallbox_charge_power }

      it { is_expected.to eq([0.0, 0.0, 0.0, 0.0]) }
    end

    describe '#case_temp' do
      subject { request.case_temp }

      it { is_expected.to eq(34.0) }
    end

    describe '#current_state' do
      subject { request.current_state }

      it { is_expected.to eq(56) }
    end

    describe '#current_state_name' do
      subject { request.current_state_name }

      it { is_expected.to eq('PEAK-SHAVING: WARTEN') }
    end

    describe '#measure_time' do
      subject { Time.at(request.measure_time) }

      it { is_expected.to eq(Time.parse('2023-08-18 09:52:57.000000000 +0200')) }
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
