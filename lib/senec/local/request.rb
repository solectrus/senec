require_relative 'value'
require_relative 'constants'

module Senec
  module Local
    class Request
      def initialize(connection:, body: BASIC_REQUEST, state_names: nil)
        @connection = connection
        @body = body
        @state_names = state_names
      end

      attr_reader :connection, :body, :state_names

      def perform!
        parsed_response
        true
      end

      def house_power
        get('ENERGY', 'GUI_HOUSE_POW')
      end

      def inverter_power
        get('ENERGY', 'GUI_INVERTER_POWER')
      end

      def mpp_power
        get('PV1', 'MPP_POWER')
      end

      def power_ratio
        get('PV1', 'POWER_RATIO')
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

      def application_version
        get('WIZARD', 'APPLICATION_VERSION')
      end

      def current_state_code
        get('ENERGY', 'STAT_STATE')
      end

      def current_state_name
        throw RuntimeError, 'No state names provided!' unless state_names

        state_names[current_state_code]
      end

      def measure_time
        web_time = get('RTC', 'WEB_TIME')
        utc_offset = get('RTC', 'UTC_OFFSET')

        web_time - (utc_offset * 60)
      end

      def response_duration
        raw_response.env[:duration]
      end

      def get(*keys)
        return unless parsed_response

        value = parsed_response.dig(*keys)

        if value.is_a?(Array)
          value.map do |v|
            Value.new(v).decoded
          end
        elsif value
          Value.new(value).decoded
        else
          raise Error, "Value missing for #{keys.join('.')}"
        end
      rescue Senec::Local::DecodingError => e
        raise Error, "Decoding failed for #{keys.join('.')}: #{e.message}"
      end

      private

      def parsed_response
        @parsed_response ||= JSON.parse(raw_response.body)
      end

      def raw_response
        @raw_response ||= begin
          response = connection.post(url, request_body, request_header)
          raise Error, response.status unless response.success?

          response
        end
      end

      def url
        '/lala.cgi'
      end

      def request_body
        JSON.generate(body)
      end

      def request_header
        {
          'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8',
          'Accept' => 'application/json, text/javascript, */*; q=0.01'
        }
      end
    end
  end
end
