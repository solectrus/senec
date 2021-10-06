module Senec
  class Value
    def initialize(data)
      @data = data
    end

    def to_f
      decoded_value
    end

    def to_i
      decoded_value.round
    end

    private

    def decoded_value
      parts  = @data.split('_')
      prefix = parts[0]
      value  = parts[1]

      case prefix
      when 'fl'
        hex2float(value)
      when 'i3', 'u1', 'u3'
        hex2int(value)
      # TODO: There are some more prefixes to handle
      else
        raise ArgumentError, "#{@data} cannot be decoded!"
      end
    end

    def hex2float(hex)
      ["0x#{hex}".to_i(16)].pack('L').unpack1('F').round(1)
    end

    def hex2int(hex)
      "0x#{hex}".to_i(16)
    end
  end
end
