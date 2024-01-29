RSpec.describe Senec::Cloud::TechnicalData do
  subject(:finder) { described_class[connection] }

  let(:connection) do
    Senec::Cloud::Connection.new(
      username: ENV.fetch('SENEC_USERNAME'),
      password: ENV.fetch('SENEC_PASSWORD'),
    )
  end

  describe '#initialize' do
    it 'sets the connection' do
      technical_data = described_class.new(connection:)
      expect(technical_data.instance_variable_get(:@connection)).to eq(connection)
    end

    it 'sets the data' do
      technical_data = described_class.new(data: { foo: 42 })
      expect(technical_data.data).to eq(foo: 42)
    end

    it 'fails without connection or data' do
      expect { described_class.new }.to raise_error(ArgumentError)
    end

    it 'fails when both connection and data given' do
      expect do
        described_class.new(connection:, data: { foo: 42 })
      end.to raise_error(ArgumentError)
    end

    it 'fails when using loaddata after setting data' do
      technical_data = described_class.new(data: { foo: 42 })

      expect { technical_data.load_data }.to raise_error(
        RuntimeError,
        'Data already present!',
      )
    end
  end

  describe 'Finder' do
    describe '#first', vcr: 'cloud/fetch-technical_data-default-system' do
      subject(:technical_data) { finder.first }

      it 'returns a TechnicalData instance' do
        expect(technical_data).to be_a(described_class)
      end

      it 'uses the default_system_id' do
        expect(technical_data.system_id).to eq(connection.default_system_id)
      end

      it 'fetches the data' do
        expect(technical_data.data).to include('mcu', 'casing')
      end
    end

    describe '#find', vcr: 'cloud/fetch-technical_data-specific-system' do
      subject(:technical_data) { finder.find(system_id) }

      context 'with VALID system_id', vcr: 'cloud/fetch-technical_data-specific-system' do
        let(:system_id) { ENV.fetch('SENEC_SYSTEM_ID') }

        it 'returns a TechnicalData instance' do
          expect(technical_data).to be_a(described_class)
        end

        it 'uses the provided system_id' do
          expect(technical_data.system_id).to eq(system_id)
        end

        it 'fetches case temp' do
          expect(technical_data.data.dig('casing', 'temperatureInCelsius')).to be_a(Float)
        end

        it 'fetches state' do
          expect(technical_data.data.dig('mcu', 'mainControllerState', 'name')).to be_a(String)
        end
      end

      context 'with INVALID system_id', vcr: 'cloud/fetch-technical_data-invalid-system' do
        let(:system_id) { 123_456 }

        it 'fails' do
          expect { technical_data }.to raise_error(Senec::Cloud::Error, 'Error 401')
        end
      end
    end
  end
end
