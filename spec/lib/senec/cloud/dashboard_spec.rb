RSpec.describe Senec::Cloud::Dashboard do
  subject(:finder) { described_class[connection] }

  let(:connection) do
    Senec::Cloud::Connection.new(
      username: ENV.fetch('SENEC_USERNAME'),
      password: ENV.fetch('SENEC_PASSWORD'),
    )
  end

  describe '#initialize' do
    it 'sets the connection' do
      dashboard = described_class.new(connection:)
      expect(dashboard.instance_variable_get(:@connection)).to eq(connection)
    end

    it 'sets the data' do
      dashboard = described_class.new(data: { foo: 42 })
      expect(dashboard.data).to eq(foo: 42)
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
      dashboard = described_class.new(data: { foo: 42 })

      expect { dashboard.load_data }.to raise_error(
        RuntimeError,
        'Data already present!',
      )
    end
  end

  describe 'Finder' do
    describe '#first', vcr: 'fetch-dashboard-default-system' do
      subject(:dashboard) { finder.first }

      it 'returns a Dashboard instance' do
        expect(dashboard).to be_a(described_class)
      end

      it 'uses the default_system_id' do
        expect(dashboard.system_id).to eq(connection.default_system_id)
      end

      it 'fetches the data' do
        expect(dashboard.data).to include('aktuell', 'heute')
      end
    end

    describe '#find', vcr: 'fetch-dashboard-specific-system' do
      subject(:dashboard) { finder.find(system_id) }

      context 'with VALID system_id', vcr: 'cloud/fetch-dashboard-specific-system' do
        let(:system_id) { ENV.fetch('SENEC_SYSTEM_ID') }

        it 'returns a Dashboard instance' do
          expect(dashboard).to be_a(described_class)
        end

        it 'uses the provided system_id' do
          expect(dashboard.system_id).to eq(system_id)
        end

        it 'fetches the data' do
          expect(dashboard.data).to include('aktuell', 'heute')
        end
      end

      context 'with INVALID system_id', vcr: 'cloud/fetch-dashboard-invalid-system' do
        let(:system_id) { 123_456 }

        it 'fails' do
          expect { dashboard }.to raise_error(Senec::Cloud::Error, 'Error 401')
        end
      end
    end
  end
end
