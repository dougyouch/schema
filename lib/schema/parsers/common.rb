# frozen_string_literal: true

require 'time'

module Schema
  module Parsers
    # Schema::Parsers::Common are parser methods for basic types
    module Common
      include StringValue

      # strings are stripped first; a blank string parses to nil without an error
      INTEGER_REGEX = /\A[-+]?\d+(?:\.0+)?\z/
      FLOAT_REGEX = /\A[-+]?\d+(?:\.\d+)?([Ee][-+]?\d+)?\z/
      # matched case-insensitively; any other string is invalid
      BOOLEAN_STRINGS = {
        '1' => true, 't' => true, 'true' => true, 'on' => true, 'y' => true, 'yes' => true,
        '0' => false, 'f' => false, 'false' => false, 'off' => false, 'n' => false, 'no' => false
      }.freeze

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

      def parse_float_as_integer(field_name, parsing_errors, value)
        unless value.finite?
          parsing_errors.add(field_name, ::Schema::ParsingErrors::INCOMPATIBLE)
          return nil
        end

        parsing_errors.add(field_name, ::Schema::ParsingErrors::INCOMPATIBLE) if (value % 1) > 0.0
        value.to_i
      end

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

      # if the string is empty return nil
      def parse_string_or_nil(field_name, parsing_errors, value)
        case value
        when String
          value.empty? ? nil : value
        when ::Hash, ::Array
          parsing_errors.add(field_name, ::Schema::ParsingErrors::INCOMPATIBLE)
          nil
        when nil
          nil
        else
          String(value)
        end
      end

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
