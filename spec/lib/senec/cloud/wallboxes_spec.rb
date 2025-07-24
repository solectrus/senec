RSpec.describe Senec::Cloud::Wallboxes, :cloud do
  let(:connection) do
    Senec::Cloud::Connection.new(
      username: ENV.fetch('SENEC_USERNAME'),
      password: ENV.fetch('SENEC_PASSWORD'),
    )
  end

  describe '#initialize' do
    it 'sets the connection' do
      wallboxes = described_class.new(connection:)
      expect(wallboxes.connection).to eq(connection)
    end

    it 'sets the system_id with default 0' do
      wallboxes = described_class.new(connection:)
      expect(wallboxes.system_id).to eq(0)
    end

    it 'sets custom system_id' do
      wallboxes = described_class.new(connection:, system_id: 1)
      expect(wallboxes.system_id).to eq(1)
    end

    it 'fails without connection' do
      expect { described_class.new }.to raise_error(ArgumentError)
    end
  end

  describe '#data' do
    context 'with default system_id 0', vcr: 'cloud/fetch-wallboxes-default-system' do
      subject(:wallboxes) { described_class.new(connection:) }

      it 'fetches the data' do
        data = wallboxes.data
        expect(data).to be_a(Array)
      end

      it 'fetches wallbox data with expected structure' do
        data = wallboxes.data

        expect(data).to all(include(
                              'id', 'sequenceNumber', 'caseSerialNumber', 'chargingMode',
                              'electricVehicleConnected', 'state', 'temperatureInCelsius',
                            ))
      end

      it 'fetches wallbox with detailed properties' do
        data = wallboxes.data

        expect(data).to all(include(
                              'minPossibleChargingCurrentInA', 'maxPossibleChargingCurrentInA',
                              'configuredMaxChargingCurrentInA', 'currentApparentChargingPowerInVa',
                              'supportedChargingModes', 'firmwareVersion', 'hardwareVersion',
                            ))
      end
    end

    context 'with custom system_id', vcr: 'cloud/fetch-wallboxes-custom-system' do
      subject(:wallboxes) { described_class.new(connection:, system_id: ENV.fetch('SENEC_SYSTEM_ID').to_i) }

      it 'uses the provided system_id' do
        expect(wallboxes.system_id).to eq(ENV.fetch('SENEC_SYSTEM_ID').to_i)
      end

      it 'fetches the data' do
        data = wallboxes.data
        expect(data).to be_a(Array)
      end
    end

    context 'with invalid system_id', vcr: 'cloud/fetch-wallboxes-invalid-system' do
      subject(:wallboxes) { described_class.new(connection:, system_id: 123_456) }

      it 'fails' do
        data = wallboxes.data
        expect(data).to eq([])
      end
    end
  end
end
