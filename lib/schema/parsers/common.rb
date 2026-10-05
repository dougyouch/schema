# frozen_string_literal: true

require 'time'

module Schema
  module Parsers
    # Schema::Parsers::Common are parser methods for basic types
    module Common
      include StringValue

      # strings are stripped first; a blank string parses to nil without an error
      INTEGER_REGEX = /\A[-+]?\d+(?:\.0+)?\z/
      # Accepted float strings, e.g. "1.5", "007.5", "1e+5".
      FLOAT_REGEX = /\A[-+]?\d+(?:\.\d+)?([Ee][-+]?\d+)?\z/
      # matched case-insensitively; any other string is invalid
      BOOLEAN_STRINGS = {
        '1' => true, 't' => true, 'true' => true, 'on' => true, 'y' => true, 'yes' => true,
        '0' => false, 'f' => false, 'false' => false, 'off' => false, 'n' => false, 'no' => false
      }.freeze

      # Parses integers; whole floats are converted, fractional ones are incompatible.
      # @return [Integer, nil]
      def parse_integer(field_name, parsing_errors, value)
        case value
        when Integer
          value
        when String
          parse_string_value(field_name, parsing_errors, value) do |str|
            str.to_i if INTEGER_REGEX.match?(str)
          end
        when Float
          parse_float_as_integer(field_name, parsing_errors, value)
        when nil
          nil
        else
          parsing_errors.add(field_name, ::Schema::ParsingErrors::UNHANDLED_TYPE)
          nil
        end
      end

      # Converts a float for parse_integer.
      # @api private
      def parse_float_as_integer(field_name, parsing_errors, value)
        unless value.finite?
          parsing_errors.add(field_name, ::Schema::ParsingErrors::INCOMPATIBLE)
          return nil
        end

        parsing_errors.add(field_name, ::Schema::ParsingErrors::INCOMPATIBLE) if (value % 1) > 0.0
        value.to_i
      end

      # Converts scalars to strings; hashes and arrays are incompatible.
      # @return [String, nil]
      def parse_string(field_name, parsing_errors, value)
        case value
        when String
          value
        when ::Hash, ::Array
          parsing_errors.add(field_name, ::Schema::ParsingErrors::INCOMPATIBLE)
          nil
        when nil
          nil
        else
          String(value)
        end
      end

      # a blank (empty or whitespace-only) string returns nil; other strings are kept as is
      def parse_string_or_nil(field_name, parsing_errors, value)
        case value
        when String
          value.strip.empty? ? nil : value
        when ::Hash, ::Array
          parsing_errors.add(field_name, ::Schema::ParsingErrors::INCOMPATIBLE)
          nil
        when nil
          nil
        else
          String(value)
        end
      end

      # Parses floats.
      # @return [Float, nil]
      def parse_float(field_name, parsing_errors, value)
        case value
        when Float
          value
        when Integer
          value.to_f
        when String
          parse_string_value(field_name, parsing_errors, value) do |str|
            Float(str) if FLOAT_REGEX.match?(str)
          end
        when nil
          nil
        else
          parsing_errors.add(field_name, ::Schema::ParsingErrors::UNHANDLED_TYPE)
          nil
        end
      end

      # Parses ISO 8601 date-times (Time.xmlschema).
      # @return [Time, nil]
      def parse_time(field_name, parsing_errors, value)
        case value
        when Time
          value
        when Date
          value.to_time
        when String
          parse_string_value(field_name, parsing_errors, value) { |str| Time.xmlschema(str) }
        when nil
          nil
        else
          parsing_errors.add(field_name, ::Schema::ParsingErrors::UNHANDLED_TYPE)
          nil
        end
      end

      # @!method parse_datetime(field_name, parsing_errors, value)
      #   Same as {#parse_time}, so `attribute :created_at, :datetime` matches ActiveRecord's type name.
      #   @return [Time, nil]
      alias parse_datetime parse_time

      # Parses ISO 8601 dates (Date.iso8601).
      # @return [Date, nil]
      def parse_date(field_name, parsing_errors, value)
        case value
        when Date
          value
        when Time
          value.to_date
        when String
          parse_string_value(field_name, parsing_errors, value) { |str| Date.iso8601(str) }
        when nil
          nil
        else
          parsing_errors.add(field_name, ::Schema::ParsingErrors::UNHANDLED_TYPE)
          nil
        end
      end

      # Parses booleans; see {BOOLEAN_STRINGS}. Numbers are true unless 0.
      # @return [Boolean, nil]
      def parse_boolean(field_name, parsing_errors, value)
        case value
        when TrueClass, FalseClass
          value
        when Integer, Float
          value != 0
        when String
          parse_string_value(field_name, parsing_errors, value) { |str| BOOLEAN_STRINGS[str.downcase] }
        when nil
          nil
        else
          parsing_errors.add(field_name, ::Schema::ParsingErrors::UNHANDLED_TYPE)
          nil
        end
      end
    end
  end
end
