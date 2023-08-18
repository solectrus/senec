RSpec.describe Senec::Value do
  subject(:value) { described_class.new(data) }

  describe '#decoded' do
    subject(:decoded) { value.decoded }

    context 'when fl' do
      let(:data) { 'fl_437E7A5F' }

      it { is_expected.to be_a(Float) }
      it { is_expected.to eq(254.5) }
    end

    context 'when i3' do
      let(:data) { 'i3_00000078' }

      it { is_expected.to be_a(Integer) }
      it { is_expected.to eq(120) }
    end

    context 'when u1' do
      let(:data) { 'u1_FFFF' }

      it { is_expected.to be_a(Integer) }
      it { is_expected.to eq(65_535) }
    end

    context 'when u3' do
      let(:data) { 'u3_FFFFFFFF' }

      it { is_expected.to be_a(Integer) }
      it { is_expected.to eq(4_294_967_295) }
    end

    context 'when u6' do
      let(:data) { 'u6_FFFFFFFFFFFFFFFF' }

      it { is_expected.to be_a(Integer) }
      it { is_expected.to eq(18_446_744_073_709_551_615) }
    end

    context 'when u8' do
      let(:data) { 'u8_FF' }

      it { is_expected.to be_a(Integer) }
      it { is_expected.to eq(255) }
    end

    context 'when st' do
      let(:data) { 'st_Test' }

      it { is_expected.to be_a(String) }
      it { is_expected.to eq('Test') }
    end

    context 'when unknown prefix' do
      let(:data) { 'xx_123' }

      it { expect { decoded }.to raise_error(Senec::DecodingError, "Unknown value 'xx_123'") }
    end

    context 'when VARIABLE_NOT_FOUND' do
      let(:data) { 'VARIABLE_NOT_FOUND' }

      it do
        expect { decoded }.to raise_error(Senec::DecodingError, "Unknown value 'VARIABLE_NOT_FOUND'")
      end
    end
  end
end
