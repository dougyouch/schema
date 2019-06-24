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
            cnt = field_options[:starting_index] || 1
            indexes = []
            # finding all headers that look like Company1Name through CompanyXName
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
          next unless field_options[:header_prefix]
          size = self.const_get(field_options[:class_name]).map_headers_to_attributes(headers, field_options[:header_prefix])
          new_schema[field_name][:size] = size
        end

        redefine_class_method(:schema, new_schema)

        max_size
      end

      def get_unmapped_field_names(header_prefix=nil)
        unmapped_fields = []
        schema.each do |field_name, field_options|
          if field_options[:type] == :has_one
            unmapped_fields += self.const_get(field_options[:class_name]).get_unmapped_field_names(header_prefix)
          elsif field_options[:type] == :has_many
            unmapped_fields += self.const_get(field_options[:class_name]).get_unmapped_field_names(field_options[:header_prefix])
          else
            next if field_options[:index] || field_options[:indexes]
            next if field_options[:alias_of]
            field_name = field_options[:aliases].first if field_options[:aliases]
            if header_prefix
              field_name = header_prefix + 'X' + field_name.to_s
            end
            unmapped_fields << field_name.to_s
          end
        end
        unmapped_fields
      end

      def get_mapped_field_names(header_prefix=nil)
        mapped_fields = []
        schema.each do |field_name, field_options|
          if field_options[:type] == :has_one
            mapped_fields += self.const_get(field_options[:class_name]).get_mapped_field_names(header_prefix)
          elsif field_options[:type] == :has_many
            mapped_fields += self.const_get(field_options[:class_name]).get_mapped_field_names(field_options[:header_prefix])
          else
            next if field_options[:alias_of]
            next unless field_options[:index] || field_options[:indexes]
            field_name = field_options[:aliases].first if field_options[:aliases]
            if header_prefix
              field_name = header_prefix + 'X' + field_name.to_s
            end
            mapped_fields << field_name.to_s
          end
        end
        mapped_fields
      end
    end
  end
end
