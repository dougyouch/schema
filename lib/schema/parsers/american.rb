# frozen_string_literal: true

require 'time'

module Schema
  module Parsers
    # Schema::Parsers::American parses dates and times in American format
    module American
      DATE_FORMAT = '%m/%d/%Y'
      TIME_FORMAT = '%m/%d/%Y %H:%M:%S'

      def parse_american_date(field_name, parsing_errors, value)
        case value
        when Date
          value
        when Time
          value.to_date
        when String
          begin
            Date.strptime(value, DATE_FORMAT)
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

      def parse_american_time(field_name, parsing_errors, value)
        case value
        when Time
          value
        when Date
          value.to_time
        when String
          begin
            Time.strptime(value, TIME_FORMAT)
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
    end
  end
end
