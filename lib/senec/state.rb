module Senec
  class State
    def initialize(connection:)
      @connection = connection
    end

    attr_reader :connection

    # Extract state names from JavaScript file, which is formatted like this:
    #
    # var system_state_name = {
    #   0: "FIRST STATE",
    #   1: "SECOND STATE",
    #   ...
    #  };
    def names
      response.match(FILE_REGEX)[0].split("\n").each_with_object({}) do |line, hash|
        key, value = line.match(LINE_REGEX)&.captures
        next unless key && value

        hash[key.to_i] = value
      end
    end

    private

    FILE_REGEX = /var system_state_name = \{(.*?)\};/m
    LINE_REGEX = /(\d+)\s*:\s*"(.*)"/

    def response
      res = connection.get url
      raise Senec::Error, res.message unless res.success?

      res.body
    end

    # Use the JavaScript file with German names from the SENEC web interface
    def url
      "#{schema}://#{host}/js/DE-de.js"
    end
  end
end
