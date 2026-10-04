# frozen_string_literal: true

require 'time'

module Schema
  module Parsers
    # Schema::Parsers::American parses dates and times in American format
    module American
      include StringValue

      # strptime format for :american_date.
      DATE_FORMAT = '%m/%d/%Y'
      # strptime format for :american_time.
      TIME_FORMAT = '%m/%d/%Y %H:%M:%S'

      # Parses MM/DD/YYYY strings; blank strings are nil.
      # @return [Date, nil]
      def parse_american_date(field_name, parsing_errors, value)
        case value
        when Date
          value
        when Time
          value.to_date
        when String
          parse_string_value(field_name, parsing_errors, value) { |str| Date.strptime(str, DATE_FORMAT) }
        when nil
          nil
        else
          parsing_errors.add(field_name, ::Schema::ParsingErrors::UNHANDLED_TYPE)
          nil
        end
      end

      # Parses MM/DD/YYYY HH:MM:SS strings; blank strings are nil.
      # @return [Time, nil]
      def parse_american_time(field_name, parsing_errors, value)
        case value
        when Time
          value
        when Date
          value.to_time
        when String
          parse_string_value(field_name, parsing_errors, value) { |str| Time.strptime(str, TIME_FORMAT) }
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
