RSpec.describe Senec::Request do
  subject(:request) { described_class.new(host: host, state_names: state_names) }

  let(:state_names) { { 54 => 'LADESCHLUSSPHASE' } }

  context 'with a valid host', vcr: { cassette_name: 'request' } do
    let(:host) { 'senec' }

    describe '#house_power' do
      subject { request.house_power }

      it { is_expected.to eq(382.0) }
    end

    describe '#inverter_power' do
      subject { request.inverter_power }

      it { is_expected.to eq(1265.0) }
    end

    describe '#mpp_power' do
      subject { request.mpp_power }

      it { is_expected.to eq([624.4, 0.0, 640.7]) }
    end

    describe '#bat_power' do
      subject { request.bat_power }

      it { is_expected.to eq(262.4) }
    end

    describe '#bat_fuel_charge' do
      subject { request.bat_fuel_charge }

      it { is_expected.to eq(100.0) }
    end

    describe '#bat_charge_current' do
      subject { request.bat_charge_current }

      it { is_expected.to eq(4.6) }
    end

    describe '#bat_voltage' do
      subject { request.bat_voltage }

      it { is_expected.to eq(57.5) }
    end

    describe '#grid_power' do
      subject { request.grid_power }

      it { is_expected.to eq(-620.7) }
    end

    describe '#wallbox_charge_power' do
      subject { request.wallbox_charge_power }

      it { is_expected.to eq([0.0, 0.0, 0.0, 0.0]) }
    end

    describe '#case_temp' do
      subject { request.case_temp }

      it { is_expected.to eq(34.5) }
    end

    describe '#current_state' do
      subject { request.current_state }

      it { is_expected.to eq(54) }
    end

    describe '#current_state_name' do
      subject { request.current_state_name }

      it { is_expected.to eq('LADESCHLUSSPHASE') }
    end

    describe '#measure_time' do
      subject { Time.at(request.measure_time) }

      it { is_expected.to eq(Time.parse('2023-08-17 15:23:51.000000000 +0200')) }
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
