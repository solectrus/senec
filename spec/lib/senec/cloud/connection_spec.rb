RSpec.describe Senec::Cloud::Connection, :cloud, :vcr do
  subject(:connection) { described_class.new(username:, password:) }

  let(:username) { ENV.fetch('SENEC_USERNAME') }

  describe '#authenticated?' do
    subject(:authenticated?) { connection.authenticated? }

    context 'when credentials are valid', vcr: 'cloud/login-valid' do
      let(:password) { ENV.fetch('SENEC_PASSWORD') }

      it { is_expected.to be_truthy }
    end

    context 'when credentials are invalid', vcr: 'cloud/login-invalid' do
      let(:password) { 'wrongpassword' }

      it { is_expected.to be_falsy }
    end
  end
end
