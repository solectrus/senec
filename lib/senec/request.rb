require 'httparty'
require 'senec/value'
require 'senec/constants'

module Senec
  class Request
    def initialize(host:, schema: 'http', state_names: nil)
      @host = host
      @schema = schema
      @state_names = state_names
    end

    attr_reader :host, :schema, :state_names

    def house_power
      get('ENERGY', 'GUI_HOUSE_POW')
    end

    def inverter_power
      get('ENERGY', 'GUI_INVERTER_POWER')
    end

    def mpp_power
      get('PV1', 'MPP_POWER')
    end

    def bat_power
      get('ENERGY', 'GUI_BAT_DATA_POWER')
    end

    def bat_fuel_charge
      get('ENERGY', 'GUI_BAT_DATA_FUEL_CHARGE')
    end

    def bat_charge_current
      get('ENERGY', 'GUI_BAT_DATA_CURRENT')
    end

    def bat_voltage
      get('ENERGY', 'GUI_BAT_DATA_VOLTAGE')
    end

    def grid_power
      get('ENERGY', 'GUI_GRID_POW')
    end

    def wallbox_charge_power
      get('WALLBOX', 'APPARENT_CHARGING_POWER')
    end

    def case_temp
      get('TEMPMEASURE', 'CASE_TEMP')
    end

    def current_state
      get('ENERGY', 'STAT_STATE')
    end

    def current_state_name
      throw RuntimeError, 'No state names provided!' unless state_names

      state_names[current_state]
    end

    def measure_time
      web_time = get('RTC', 'WEB_TIME')
      utc_offset = get('RTC', 'UTC_OFFSET')

      web_time - (utc_offset * 60)
    end

    private

    def get(*keys)
      value = response.dig(*keys)

      if value.is_a?(Array)
        value.map do |v|
          Senec::Value.new(v).decoded
        end
      elsif value
        Senec::Value.new(value).decoded
      else
        raise Senec::Error, "Value missing for #{keys.join('.')}"
      end
    rescue DecodingError => e
      raise Senec::Error, "Decoding failed for #{keys.join('.')}: #{e.message}"
    end

    def response
      @response ||= begin
        res = HTTParty.post(
          url,
          body: JSON.generate(Senec::BASIC_REQUEST),
          headers: {
            'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8'
          },
          verify: false
        )
        raise Senec::Error, res.message.to_s unless res.success?

        res.parsed_response
      end
    end

    def url
      "#{schema}://#{host}/lala.cgi"
    end
  end
end
