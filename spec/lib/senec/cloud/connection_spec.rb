RSpec.describe Senec::Cloud::Connection, :cloud, :vcr do
  let(:connection) { described_class.new(username:, password:, totp_uri:) }

  let(:username) { ENV.fetch('SENEC_USERNAME') }
  let(:password) { ENV.fetch('SENEC_PASSWORD') }
  let(:totp_uri) { ENV.fetch('SENEC_TOTP_URI') }

  describe '#authenticate!' do
    subject(:authenticate!) { connection.authenticate! }

    context 'when credentials are valid', vcr: 'cloud/login-valid' do
      it { expect { authenticate! }.to change(connection, :authenticated?).from(false).to(true) }
    end

    context 'when credentials are invalid', vcr: 'cloud/login-invalid' do
      let(:password) { 'wrongpassword' }

      it { expect { authenticate! }.to raise_error(RuntimeError, /Login failed/) }
    end

    context 'when MFA is required', vcr: 'cloud/login-mfa-required' do
      it { expect { authenticate! }.to change(connection, :authenticated?).from(false).to(true) }
    end

    context 'when MFA is required, but URI not given', vcr: 'cloud/login-mfa-required' do
      let(:totp_uri) { nil }

      it { expect { authenticate! }.to raise_error(RuntimeError, 'MFA required but no TOTP URI provided') }
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

  describe 'token refresh behavior' do
    subject(:response) { connection.systems }

    let(:oauth_response) { instance_double(OAuth2::Response, body: [{ 'id' => '12345' }].to_json) }

    before { allow(connection).to receive(:authenticate!) }

    it 'uses valid tokens directly' do
      token = instance_double(OAuth2::AccessToken, expired?: false)
      allow(token).to receive(:get).and_return(oauth_response)
      connection.instance_variable_set(:@oauth_token, token)

      expect(response).to be_a(Array)
      expect(connection).not_to have_received(:authenticate!)
    end

    it 'refreshes expired tokens successfully' do
      old_token = instance_double(OAuth2::AccessToken, expired?: true)
      new_token = instance_double(OAuth2::AccessToken)
      allow(old_token).to receive(:refresh!).and_return(new_token)
      allow(new_token).to receive(:get).and_return(oauth_response)
      connection.instance_variable_set(:@oauth_token, old_token)

      expect(response).to be_a(Array)
      expect(connection).not_to have_received(:authenticate!)
    end

    it 're-authenticates when token refresh fails' do
      old_token = instance_double(OAuth2::AccessToken, expired?: true)
      new_token = instance_double(OAuth2::AccessToken)
      allow(old_token).to receive(:refresh!).and_raise(OAuth2::Error.new('invalid_grant'))
      allow(connection).to receive(:authenticate!) { connection.instance_variable_set(:@oauth_token, new_token) }
      allow(new_token).to receive(:get).and_return(oauth_response)
      connection.instance_variable_set(:@oauth_token, old_token)

      expect(response).to be_a(Array)
      expect(connection).to have_received(:authenticate!)
    end
  end
end
