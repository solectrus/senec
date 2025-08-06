RSpec.describe Senec::Cloud::Connection, :cloud, :vcr do
  subject(:connection) { described_class.new(username:, password:) }

  let(:username) { ENV.fetch('SENEC_USERNAME') }
  let(:password) { ENV.fetch('SENEC_PASSWORD') }

  describe '#authenticate!' do
    subject(:authenticate!) { connection.authenticate! }

    context 'when credentials are valid', vcr: 'cloud/login-valid' do
      it { expect { authenticate! }.to change(connection, :authenticated?).from(false).to(true) }
    end

    context 'when credentials are invalid', vcr: 'cloud/login-invalid' do
      let(:password) { 'wrongpassword' }

      it { expect { authenticate! }.to raise_error(RuntimeError, /Login failed/) }
    end
  end

  describe '#systems', vcr: 'cloud/systems' do
    subject(:systems) { connection.systems }

    before { connection.authenticate! }

    it { is_expected.to be_an(Array) }
    it { is_expected.to all(be_a(Hash)) }

    it 'returns systems with expected keys' do
      expect(systems.first.keys).to include(
        'caseNumber',
        'city',
        'controlUnitNumber',
        'countryCode',
        'houseNumber',
        'id',
        'postalCode',
        'product',
        'street',
        'timezoneText',
        'wallboxIds',
      )
    end
  end

  describe '#system_details' do
    subject(:system_details) { connection.system_details(system_id) }

    before { connection.authenticate! }

    context 'with valid system_id', vcr: 'cloud/system-details' do
      let(:system_id) { ENV.fetch('SENEC_SYSTEM_ID') }

      it { is_expected.to be_a(Hash) }

      it 'returns details' do
        expect(system_details.keys).to include(
          'batteryModules',
          'batteryPack',
          'casing',
          'installer',
          'mcu',
          'systemOverview',
          'warranty',
        )
      end
    end

    context 'with invalid system_id', vcr: 'cloud/system-details-invalid-id' do
      let(:system_id) { '12345' }

      it 'returns nil' do
        expect(system_details).to be_nil
      end
    end
  end

  describe '#dashboard' do
    subject(:dashboard) { connection.dashboard(system_id) }

    before { connection.authenticate! }

    context 'with valid system_id', vcr: 'cloud/dashboard' do
      let(:system_id) { ENV.fetch('SENEC_SYSTEM_ID') }

      it { is_expected.to be_a(Hash) }

      it 'returns details' do
        expect(dashboard.keys).to include(
          'electricVehicleConnected',
          'numberOfWallboxes',
          'storageDeviceState',
          'systemId',
          'systemType',
          'timestamp',
          'currently',
          'today',
        )
      end
    end

    context 'with invalid system_id', vcr: 'cloud/dashboard-invalid-id' do
      let(:system_id) { '12345' }

      it 'returns nil' do
        expect(dashboard).to be_nil
      end
    end
  end

  describe '#wallbox' do
    subject(:wallbox) { connection.wallbox(system_id, 1) }

    before { connection.authenticate! }

    context 'with valid system_id', vcr: 'cloud/wallbox' do
      let(:system_id) { ENV.fetch('SENEC_SYSTEM_ID') }

      it { is_expected.to be_a(Hash) }

      it 'returns details' do
        expect(wallbox.keys).to include(
          'chargingCurrents',
          'chargingMode',
          'chargingPowerStats',
          'controllerId',
          'disconnected',
          'id',
          'isInterchargeAvailable',
          'isSolarChargingAvailable',
          'name',
          'productFamily',
          'prohibitUsage',
          'state',
          'type',
        )
      end
    end

    context 'with invalid system_id', vcr: 'cloud/wallbox-invalid-id' do
      let(:system_id) { '12345' }

      it 'returns nil' do
        expect(wallbox).to be_nil
      end
    end
  end

  describe '#wallbox_search' do
    subject(:wallbox_search) { connection.wallbox_search(system_id) }

    before { connection.authenticate! }

    context 'with valid system_id', vcr: 'cloud/wallbox_search' do
      let(:system_id) { ENV.fetch('SENEC_SYSTEM_ID') }

      it { is_expected.to be_a(Array) }

      it 'returns wallbox details' do
        expect(wallbox_search.first.keys).to include(
          'chargingCurrents',
          'chargingMode',
          'chargingPowerStats',
          'controllerId',
          'disconnected',
          'id',
          'isInterchargeAvailable',
          'isSolarChargingAvailable',
          'name',
          'productFamily',
          'prohibitUsage',
          'state',
          'type',
        )
      end
    end

    context 'with invalid system_id', vcr: 'cloud/wallbox_search-invalid-id' do
      let(:system_id) { '12345' }

      it 'returns nil' do
        expect(wallbox_search).to be_nil
      end
    end
  end
end
