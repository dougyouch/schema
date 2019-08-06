# frozen_string_literal: true

module Schema
  module Parsers
    # Schema::Parsers::Array adds the array type to schemas
    module Array
      def parse_array(field_name, parsing_errors, value)
        case value
        when ::Array
          value
        else
          parsing_errors.add(field_name, :incompatable)
          nil
        end
      end
    end
  end
end
