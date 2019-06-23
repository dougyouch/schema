module Schema
  module ArrayHeaders
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def map_headers_to_attributes(headers, header_prefix=nil)
        new_schema = schema.dup

        max_size = header_prefix ? 0 : nil

        schema.each do |field_name, field_options|
          if header_prefix
            cnt = 1
            indexes = []
            while index = headers.index(header_prefix + cnt.to_s + field_options[:key])
              cnt += 1
              indexes << index
            end

            if ! indexes.empty?
              new_schema[field_options[:alias_of] || field_name][:indexes] = indexes
              max_size = indexes.size unless max_size > indexes.size
            end
          else
            if index = headers.index(field_options[:key])
              new_schema[field_options[:alias_of] || field_name][:index] = index
            end
          end
        end

        schema.each do |_, field_options|
          next unless field_options[:type] == :has_one
          size = self.const_get(field_options[:class_name]).map_headers_to_attributes(headers, header_prefix)

          if header_prefix
            max_size = size if max_size < size
          end
        end

        schema.each do |field_name, field_options|
          next unless field_options[:type] == :has_many
          size = self.const_get(field_options[:class_name]).map_headers_to_attributes(headers, field_options[:header_prefix])
          new_schema[field_name][:size] = size
        end

        redefine_class_method(:schema, new_schema)

        max_size
      end
    end
  end
end
