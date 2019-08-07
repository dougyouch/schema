# frozen_string_literal: true

module Schema
  module Parsers
    # Schema::Parsers::Hash adds the hash type to schemas
    module Hash
      def parse_hash(field_name, parsing_errors, value)
        case value
        when ::Hash
          value
        else
          parsing_errors.add(field_name, ::Schema::ParsingErrors::INCOMPATABLE)
          nil
        end
      end
    end
  end
end
