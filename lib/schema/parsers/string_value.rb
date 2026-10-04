# frozen_string_literal: true

module Schema
  module Parsers
    # Schema::Parsers::StringValue is the shared string handling for parsers
    module StringValue
      # strips the string, returns nil when it's blank, and otherwise yields it; a nil result
      # or an ArgumentError (e.g. Date::Error) from the block is recorded as invalid
      def parse_string_value(field_name, parsing_errors, value)
        str = value.strip
        return nil if str.empty?

        result = begin
          yield str
        rescue ArgumentError
          nil
        end
        parsing_errors.add(field_name, ::Schema::ParsingErrors::INVALID) if result.nil?
        result
      end
    end
  end
end
