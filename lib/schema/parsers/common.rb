# frozen_string_literal: true

require 'time'

module Schema
  module Parsers
    # Schema::Parsers::Common are parser methods for basic types
    module Common
      INTEGER_REGEX = /^[-+]?(?:[1-9]\d*|0)(?:\.0+)?$/
      FLOAT_REGEX = /^[-+]?(?:[1-9]\d*|0)(?:\.\d+)?([Ee]-?\d+)?$/
      BOOLEAN_REGEX = /^(?:1|t|true|on|y|yes)$/i

      def parse_integer(field_name, parsing_errors, value)
        case value
        when Integer
          value
        when String
          if INTEGER_REGEX.match(value)
            value.to_i
          else
            parsing_errors.add(field_name, ::Schema::ParsingErrors::INVALID)
            nil
          end
        when Float
          parsing_errors.add(field_name, ::Schema::ParsingErrors::INCOMPATABLE) if (value % 1) > 0.0
          value.to_i
        when nil
          nil
        else
          parsing_errors.add(field_name, ::Schema::ParsingErrors::UNHANDLED_TYPE)
          nil
        end
      end

      def parse_string(field_name, parsing_errors, value)
        case value
        when String
          value
        when ::Hash, ::Array
          parsing_errors.add(field_name, ::Schema::ParsingErrors::INCOMPATABLE)
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
          parsing_errors.add(field_name, ::Schema::ParsingErrors::INCOMPATABLE)
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
          if FLOAT_REGEX.match(value)
            Float(value)
          else
            parsing_errors.add(field_name, ::Schema::ParsingErrors::INVALID)
            nil
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
          begin
            Time.xmlschema(value)
          rescue ArgumentError
            parsing_errors.add(field_name, ::Schema::ParsingErrors::INVALID)
            nil
          end
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
          begin
            Date.parse(value)
          rescue ArgumentError
            parsing_errors.add(field_name, ::Schema::ParsingErrors::INVALID)
            nil
          end
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
          BOOLEAN_REGEX.match?(value)
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
