module Schema
  module Parsers
    module Common
      def parse_integer(field_name, parsing_errors, value)
        case value
        when Integer
          value
        when String
          if value =~ /^(?:[1-9]\d*|0)$/
            Integer(value)
          else
            parsing_errors.add(field_name, :invalid)
            nil
          end
        when Float
          if (value % 1) > 0.0
            parsing_errors.add(field_name, :incompatable)
          end
          value.to_i
        else
          parsing_errors.add(field_name, :unhandled_type)
          nil
        end
      end

      def parse_string(field_name, parsing_errors, value)
        case value
        when String
          value
        when Hash, Array
          parsing_errors.add(field_name, :incompatable)
          nil
        else
          String(value)
        end
      end

      def parse_number(field_name, parsing_errors, value)
        case value
        when Float
          value
        when Integer
          value.to_f
        when String
          if value =~ /^(?:[1-9]\d*|0)(?:\.\d+)?$/
            Float(value)
          else
            parsing_errors.add(field_name, :invalid)
            nil
          end
        else
          parsing_errors.add(field_name, :unhandled_type)
          nil
        end
      end
    end
  end
end

