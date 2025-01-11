RSpec.describe Senec::Cloud::Dashboard do
  subject(:finder) { described_class[connection] }

  let(:connection) do
    Senec::Cloud::Connection.new(
      username: ENV.fetch('SENEC_USERNAME'),
      password: ENV.fetch('SENEC_PASSWORD'),
    )
  end

  describe 'Finder' do
    describe '#first' do
      subject(:dashboard) { finder.first }

      it 'returns a Dashboard instance', vcr: 'cloud/fetch-dashboard-v1-default-system' do
        expect(dashboard).to be_a(described_class)
      end

      it 'uses the default_system_id', vcr: 'cloud/fetch-dashboard-v1-default-system' do
        expect(dashboard.system_id).to eq(connection.default_system_id)
      end
    end

    describe '#find' do
      subject(:dashboard) { finder.find(system_id) }

      context 'with VALID system_id' do
        let(:system_id) { ENV.fetch('SENEC_SYSTEM_ID') }

        it 'returns a Dashboard instance' do
          expect(dashboard).to be_a(described_class)
        end

        it 'uses the provided system_id' do
          expect(dashboard.system_id).to eq(system_id)
        end
      end

      context 'with INVALID system_id', vcr: 'cloud/fetch-dashboard-invalid-system' do
        let(:system_id) { 123_456 }

        it 'fails' do
          expect { dashboard.data }.to raise_error(Senec::Cloud::Error, 'Error 401')
        end
      end
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
    end

    describe '#data' do
      let(:dashboard) { finder.first }

      context 'with default version of 1', vcr: 'cloud/fetch-dashboard-v1-default-system' do
        subject(:data) { dashboard.data }

        it 'fetches the data' do
          expect(data).to include('aktuell', 'heute')
        end

        it 'fetches data with keys' do
          expected_keys = %w[
            stromerzeugung
            stromverbrauch
            netzeinspeisung
            netzbezug
            speicherbeladung
            speicherentnahme
            speicherfuellstand
            autarkie
            wallbox
          ]

          %w[aktuell heute].each do |key|
            expect(data[key].keys).to match_array(expected_keys)
          end
        end
      end

      context 'with version 2', vcr: 'cloud/fetch-dashboard-v2-default-system' do
        subject(:data) { dashboard.data(version: 'v2') }

        it 'fetches the data' do
          expect(data).to include('currently', 'today')
        end

        it 'fetches currently data' do
          expect(data['currently'].keys).to match_array(
            %w[
              batteryChargeInW
              batteryDischargeInW
              batteryLevelInPercent
              gridDrawInW
              gridFeedInInW
              powerConsumptionInW
              powerGenerationInW
              selfSufficiencyInPercent
              wallboxInW
            ],
          )
        end

        it 'fetches today data' do
          expect(data['today'].keys).to match_array(
            %w[
              batteryChargeInWh
              batteryDischargeInWh
              batteryLevelInPercent
              gridDrawInWh
              gridFeedInInWh
              powerConsumptionInWh
              powerGenerationInWh
              selfSufficiencyInPercent
              wallboxInWh
            ],
          )
        end
      end
    end
  end
end
