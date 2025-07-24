RSpec.describe Senec::Cloud::StatsOverview, :cloud do
  let(:connection) do
    Senec::Cloud::Connection.new(
      username: ENV.fetch('SENEC_USERNAME'),
      password: ENV.fetch('SENEC_PASSWORD'),
    )
  end

  describe '#initialize' do
    it 'sets the connection' do
      stats_overview = described_class.new(connection:)
      expect(stats_overview.instance_variable_get(:@connection)).to eq(connection)
    end

    it 'sets the system_id with default 0' do
      stats_overview = described_class.new(connection:)
      expect(stats_overview.system_id).to eq(0)
    end
  end

  describe '#data' do
    let(:expected_keys) { %w[gridimport powergenerated consumption gridexport accuexport accuimport acculevel] }

    context 'with default system_id 0', vcr: 'cloud/fetch-stats-overview-default-system' do
      subject(:stats_overview) { described_class.new(connection:) }

      it 'fetches the data' do
        data = stats_overview.data
        expect(data).to include(*expected_keys)
      end

      it 'fetches data with expected structure' do
        data = stats_overview.data

        expected_keys.each do |key|
          expect(data[key]).to include('today', 'now')
        end
      end

      it 'has numeric values for today' do
        data = stats_overview.data

        expected_keys.each do |key|
          expect(data[key]['today']).to be_a(Numeric)
        end
      end

      it 'has numeric values for now' do
        data = stats_overview.data

        expected_keys.each do |key|
          expect(data[key]['now']).to be_a(Numeric)
        end
      end

      it 'includes system information' do
        data = stats_overview.data
        expect(data).to include(
          'senecBatteryStorageGeneration', 'machine', 'state',
        )
      end
    end
  end
end
