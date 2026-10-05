# frozen_string_literal: true

require 'bigdecimal'

module Schema
  module Parsers
    # Schema::Parsers::Decimal parses :decimal attributes into BigDecimal, for money and other
    # exact values. Included by Schema::All. On Ruby 3.4+ bigdecimal is a bundled gem; ActiveModel
    # already depends on it, otherwise add it to your Gemfile.
    module Decimal
      include StringValue

      # Accepted decimal strings, e.g. "12", "-0.50", "1.5e3".
      DECIMAL_REGEX = /\A[-+]?(?:\d+(?:\.\d*)?|\.\d+)(?:[Ee][-+]?\d+)?\z/

      # Parses decimals from strings and numbers; hashes and arrays are incompatible.
      # @return [BigDecimal, nil]
      def parse_decimal(field_name, parsing_errors, value)
        case value
        when BigDecimal then value
        when Integer, Rational then BigDecimal(value, 0)
        when Float then parse_float_as_decimal(field_name, parsing_errors, value)
        when String
          parse_string_value(field_name, parsing_errors, value) { |str| BigDecimal(str) if DECIMAL_REGEX.match?(str) }
        when nil then nil
        when ::Hash, ::Array then add_decimal_error(field_name, parsing_errors, ::Schema::ParsingErrors::INCOMPATIBLE)
        else add_decimal_error(field_name, parsing_errors, ::Schema::ParsingErrors::UNHANDLED_TYPE)
        end
      end

      private

      # floats go through their shortest string form, so 1.1 becomes 1.1 and not 1.100000000000000088...
      def parse_float_as_decimal(field_name, parsing_errors, value)
        return add_decimal_error(field_name, parsing_errors, ::Schema::ParsingErrors::INCOMPATIBLE) unless value.finite?

        BigDecimal(value.to_s)
      end

      def add_decimal_error(field_name, parsing_errors, code)
        parsing_errors.add(field_name, code)
        nil
      end
    end
  end
end
