# frozen_string_literal: true

module Schema
  module Parsers
    # Schema::Parsers::Hash adds the hash type to schemas
    module Hash
      # Accepts hashes; anything else is incompatible.
      # @return [Hash, nil]
      def parse_hash(field_name, parsing_errors, value)
        case value
        when ::Hash
          value
        when nil
          nil
        else
          parsing_errors.add(field_name, ::Schema::ParsingErrors::INCOMPATIBLE)
          nil
        end
      end
    end
  end
end
