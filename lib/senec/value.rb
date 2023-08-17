module Senec
  class Value
    def initialize(data)
      @data = data
    end

    def decoded
      parts  = @data.split('_')
      prefix = parts[0]
      value  = parts[1]

      case prefix
      when 'fl'
        decoded_float(value)
      when 'i3', 'u1', 'u3', 'u6', 'u8'
        decoded_int(value)
      when 'st'
        value
      # TODO: There are some more prefixes to handle
      else
        raise Senec::DecodingError, "Unknown value '#{@data}'"
      end
    end

    alias to_i decoded
    alias to_f decoded
    alias to_s decoded

    private

    def decoded_float(hex)
      ["0x#{hex}".to_i(16)].pack('L').unpack1('F').round(1)
    end

    def decoded_int(hex)
      "0x#{hex}".to_i(16)
    end
  end
end
