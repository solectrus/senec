RSpec.describe Senec::Cloud::Connection, :vcr do
  subject(:connection) { described_class.new(username:, password:, token:) }

  let(:username) { ENV.fetch('SENEC_USERNAME') }
  let(:password) { ENV.fetch('SENEC_PASSWORD') }
  let(:token) { nil }
  let(:system_id) { ENV.fetch('SENEC_SYSTEM_ID') }

  describe '#authenticated?' do
    subject(:authenticated?) { connection.authenticated? }

    context 'when credentials are valid', vcr: 'cloud/login-valid' do
      it { is_expected.to be_truthy }
    end

    context 'when credentials are invalid', vcr: 'cloud/login-invalid' do
      let(:password) { 'wrongpassword' }

      it { expect { authenticated? }.to raise_error('Error 401') }
    end

    context 'when valid token is given', vcr: 'cloud/login-valid' do
      let(:token) { described_class.new(username:, password:).token }

      it { is_expected.to be_truthy }

      it 'can access data', vcr: 'cloud/login-by-valid-token' do
        expect(connection.systems).to be_a(Array)
      end
    end

    context 'when invvalid token is given' do
      let(:token) { 'Z3VwcmdAcGVkZXJtYW9uLnRldjpnNzVybnd4M5k=' } # Fake token

      it { is_expected.to be_truthy }

      it 'cannot access data', vcr: 'cloud/login-by-invalid-token' do
        expect { connection.systems }.to raise_error(Senec::Cloud::Error, 'Error 401')
      end
    end
  end

  describe '#systems', vcr: 'cloud/fetch-systems' do
    subject(:systems) { connection.systems }

    it do
      expect(systems).to all include(
        'gehaeusenummer',
        'hausnummer',
        'id',
        'ort',
        'postleitzahl',
        'steuereinheitnummer',
        'strasse',
        'systemType',
        'wallboxIds',
        'zeitzone',
      )
    end
  end

  describe '#default_system_id', vcr: 'cloud/fetch-systems' do
    subject { connection.default_system_id }

    it { is_expected.to eq(system_id) }
  end
end
