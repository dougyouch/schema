# frozen_string_literal: true

module Schema
  module Parsers
    # Schema::Parsers::Array adds the array type to schemas
    module Array
      def parse_array(field_name, parsing_errors, value)
        case value
        when ::Array
          value
        when String
          schema_options = self.class.schema[field_name]
          if (data = Array.parse_string_array(self, field_name, parsing_errors, value, schema_options))
            return data
          end

          parsing_errors.add(field_name, :incompatable)
          nil
        else
          parsing_errors.add(field_name, :incompatable)
          nil
        end
      end

      def self.parse_string_array(model, field_name, parsing_errors, value, schema_options)
        return nil unless (separator = schema_options[:separator])

        convert_array_values(model, field_name, parsing_errors, value.split(separator), schema_options)
      end

      def self.convert_array_values(model, field_name, parsing_errors, data, schema_options)
        return data unless (data_type = schema_options[:data_type])

        parser_method = "parse_#{data_type}"
        data.each_with_index.map do |datum, idx|
          model.send(parser_method, "#{field_name}:#{idx}", parsing_errors, datum)
        end
      end
    end
  end
end
