RSpec.describe Senec::Request do
  subject(:request) { described_class.new(host: host) }

  context 'with a valid host', vcr: { cassette_name: 'request' } do
    let(:host) { 'senec' }

    describe '#house_power' do
      subject { super().house_power }

      it { is_expected.to eq(511.6) }
    end

    describe '#inverter_power' do
      subject { super().inverter_power }

      it { is_expected.to eq(2338.7) }
    end

    describe '#bat_power' do
      subject { super().bat_power }

      it { is_expected.to eq(1792.9) }
    end

    describe '#bat_fuel_charge' do
      subject { super().bat_fuel_charge }

      it { is_expected.to eq(51.5) }
    end

    describe '#bat_charge_current' do
      subject { super().bat_charge_current }

      it { is_expected.to eq(34.0) }
    end

    describe '#bat_voltage' do
      subject { super().bat_voltage }

      it { is_expected.to eq(52.7) }
    end

    describe '#grid_power' do
      subject { super().grid_power }

      it { is_expected.to eq(-34.3) }
    end

    describe '#wallbox_charge_power' do
      subject { super().wallbox_charge_power }

      it { is_expected.to eq([0.0, 0.0, 0.0, 0.0]) }
    end

    describe '#case_temp' do
      subject { super().case_temp }

      it { is_expected.to eq(34.6) }
    end

    describe '#current_state' do
      subject { super().current_state }

      it { is_expected.to eq('CHARGE') }
    end

    describe '#measure_time' do
      subject { Time.at(super().measure_time) }

      it { is_expected.to eq(Time.parse('2022-11-13 09:30:05.000000000 +0100')) }
    end
  end

  context 'when host does not exist', vcr: true do
    let(:host) { 'invalid-host' }

    it 'raises an error' do
      expect { request.house_power }.to raise_error(HTTP::ConnectionError)
    end
  end

  context 'when host is present but does not respond accordingly', vcr: { cassette_name: 'request-error' } do
    let(:host) { 'example.com' }

    it 'raises an error' do
      expect { request.house_power }.to raise_error(Senec::Error, '404 Not Found')
    end
  end
end
