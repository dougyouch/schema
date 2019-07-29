# frozen_string_literal: true

module Schema
  # Schema::CSVParser is used to create schema models from a csv
  class CSVParser
    include Enumerable

    def initialize(csv, schema_class, headers = nil)
      @csv = csv
      @schema_class = schema_class
      @headers = headers || csv.shift
      @mapped_headers = schema_class.map_headers_to_attributes(@headers)
    end

    def missing_fields(required_fields)
      required_fields - get_mapped_headers(@mapped_headers)
    end

    def shift
      return unless (row = @csv.shift)

      @schema_class.from_array(row, @mapped_headers)
    end

    def each
      while (schema = shift)
        yield schema
      end
    end

    def get_mapped_headers(mapped_headers)
      indexed_headers = []
      mapped_headers.each do |_, info|
        if (index = info[:index])
          indexed_headers << @headers[index]
        elsif (indexes = info[:indexes])
          indexed_headers += indexes.map { |index| @headers[index] }
        else
          indexed_headers += get_mapped_headers(info)
        end
      end
      indexed_headers
    end
  end
end
