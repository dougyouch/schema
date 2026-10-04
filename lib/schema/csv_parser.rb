# frozen_string_literal: true

module Schema
  # Schema::CSVParser is used to create schema models from a csv
  class CSVParser
    include Enumerable

    def initialize(csv, schema_class, headers = nil)
      @csv = csv
      @schema_class = schema_class
      @headers = clean_headers((headers || csv.shift) || [])
      @mapped_headers = schema_class.map_headers_to_attributes(@headers)
    end

    # strips whitespace, treats empty header cells as "", and drops the UTF-8 byte order mark
    # that Excel puts before the first header
    def clean_headers(headers)
      headers.map.with_index do |header, idx|
        header = header.to_s.strip
        idx.zero? ? header.delete_prefix("\uFEFF") : header
      end
    end

    # Required header names the CSV doesn't map.
    # @param required_fields [Array<String>]
    # @return [Array<String>]
    def missing_fields(required_fields)
      required_fields - get_mapped_headers(@mapped_headers)
    end
    alias missing_headers missing_fields

    # Reads the next row.
    # @return [Schema::Model, nil] nil at the end of the CSV
    def shift
      return unless (row = @csv.shift)

      @schema_class.from_array(row, @mapped_headers)
    end

    # Yields a model for each remaining row.
    # @yieldparam model [Schema::Model]
    def each
      while (schema = shift)
        yield schema
      end
    end

    # Header names covered by a mapping.
    # @api private
    def get_mapped_headers(mapped_headers)
      indexed_headers = []
      mapped_headers.each_value do |info|
        if (index = info[:index])
          indexed_headers << @headers[index]
        elsif (indexes = info[:indexes])
          indexed_headers += indexes.map { |i| @headers[i] }
        else
          indexed_headers += get_mapped_headers(info)
        end
      end
      indexed_headers
    end
  end
end
