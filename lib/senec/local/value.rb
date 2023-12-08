module Senec
  module Local
    class Value
      def initialize(raw)
        @raw = raw
        @prefix, @value = raw&.split('_')
      end

      attr_reader :prefix, :value, :raw

      def decoded
        case prefix
        when 'fl'
          decoded_float(value)
        when 'i3', 'u1', 'u3', 'u6', 'u8'
          decoded_int(value)
        when 'st'
          value
        # TODO: There are some more prefixes to handle
        else
          raise DecodingError, "Unknown value '#{@raw}'"
        end
      end

      alias to_i decoded
      alias to_f decoded
      alias to_s decoded

      private

      PREFIXES = %w[fl i3 u1 u3 u6 u8 st].freeze
      private_constant :PREFIXES

      def decoded_float(hex)
        ["0x#{hex}".to_i(16)].pack('L').unpack1('F').round(1)
      end

      def decoded_int(hex)
        "0x#{hex}".to_i(16)
      end
    end
  end
end
