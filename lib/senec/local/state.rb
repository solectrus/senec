module Senec
  module Local
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
      def names(language: :de)
        js_content = response(language:)

        # Extract the matched content
        match = js_content.match(FILE_REGEX)
        return unless match

        # Extract the JSON-like part
        json_like = "{#{match[1]}}"

        # The keys are numbers, which is not valid JSON, so we need to convert them to strings
        json = json_like.gsub(/(\d+)\s*:/, '"\1":')

        # Convert the JSON string to a Ruby hash
        hash = JSON.parse(json)

        # Convert keys from strings to integers
        hash.transform_keys(&:to_i)
      end

      private

      # Regex pattern to match the system_state_name definition in the JavaScript file
      # The file may be minimized, so we need to be flexible with whitespace and line breaks
      FILE_REGEX = /system_state_name\s*=\s*{\s*([^}]*)\s*}/m

      def response(language:)
        res = connection.get url(language:)
        raise Error, res.message unless res.success?

        res.body
      end

      # Use the JavaScript file containing English/German/Italian names from the SENEC web interface
      def url(language:)
        case language
        when :en
          '/js/EN-en.js'
        when :de
          '/js/DE-de.js'
        when :it
          '/js/IT-it.js'
        else
          raise Error, "Language #{language} not supported"
        end
      end
    end
  end
end
