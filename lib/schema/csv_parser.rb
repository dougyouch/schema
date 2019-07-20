# frozen_string_literal: true

module Schema
  # Schema::CSVParser is used to create schema models from a csv
  class CSVParser
    include Enumerable

    def initialize(csv, schema_class, headers = nil)
      @csv = csv
      @schema_class = schema_class
      schema_class.map_headers_to_attributes(headers || csv.shift)
    end

    def has_required_fields?(required_fields)
      (required_fields - @schema_class.get_mapped_field_names).empty?
    end

    def shift
      if (row = @csv.shift)
        @schema_class.from_array(row)
      end
    end

    def each
      while (schema = shift)
        yield schema
      end
    end
  end
end
