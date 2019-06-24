module Schema
  class CSVParser
    include Enumerable

    def initialize(csv, schema_class)
      @csv = csv
      @schema_class = schema_class
      schema_class.map_headers_to_attributes(csv.shift)
    end

    def has_required_fields?(required_fields)
      (required_fields - @schema_class.get_mapped_field_names).empty?
    end

    def each
      while row = @csv.shift
        yield @schema_class.from_array(row)
      end
    end
  end
end
