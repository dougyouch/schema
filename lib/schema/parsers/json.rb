# frozen_string_literal: true

require 'json'

module Schema
  module Parsers
    # Schema::Parsers::Json parse the string as json
    module Json
      def parse_json(field_name, parsing_errors, value)
        case value
        when String
          begin
            ::JSON.parse(value)
          rescue ::JSON::ParserError
            parsing_errors.add(field_name, :invalid)
            nil
          end
        else
          parsing_errors.add(field_name, :incompatable)
          nil
        end
      end
    end
  end
end
