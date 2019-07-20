# frozen_string_literal: true

module Schema
  # Schema::ArrayHeaders maps columns to schema attributes
  module ArrayHeaders
    def self.included(base)
      base.extend ClassMethods
    end

    # adds methods to the class
    module ClassMethods
      def map_headers_to_attributes(headers, header_prefix = nil)
        new_schema = schema.dup
        max_size = header_prefix ? 0 : nil
        max_size = map_headers_to_fields(headers, new_schema, header_prefix, max_size)
        max_size = map_headers_to_has_one_associations(headers, new_schema, header_prefix, max_size)
        map_headers_to_has_many_associations(headers, new_schema)
        redefine_class_method(:schema, new_schema)
        max_size
      end

      def get_unmapped_field_names(header_prefix = nil)
        get_field_names(header_prefix, false)
      end

      def get_mapped_field_names(header_prefix = nil)
        get_field_names(header_prefix, true)
      end

      def get_field_names(header_prefix = nil, mapped = true)
        fields = []
        schema.each do |field_name, field_options|
          if field_options[:type] == :has_one
            fields += const_get(field_options[:class_name]).get_field_names(header_prefix, mapped)
          elsif field_options[:type] == :has_many
            fields += const_get(field_options[:class_name]).get_field_names(field_options[:header_prefix], mapped)
          else
            next if field_options[:alias_of]
            next unless mapped == mapped_field?(field_options)

            field_name = field_options[:aliases].first if field_options[:aliases]
            field_name = header_prefix + 'X' + field_name.to_s if header_prefix
            fields << field_name.to_s
          end
        end
        fields
      end

      private

      def mapped_field?(field_options)
        (field_options[:index] || field_options[:indexes]) != nil
      end

      def map_headers_to_has_one_associations(headers, new_schema, header_prefix, max_size)
        new_schema.each do |_, field_options|
          next unless field_options[:type] == :has_one

          size = const_get(field_options[:class_name]).map_headers_to_attributes(headers, header_prefix)

          max_size = size if header_prefix && max_size < size
        end
        max_size
      end

      def map_headers_to_has_many_associations(headers, new_schema)
        new_schema.each do |field_name, field_options|
          next unless field_options[:type] == :has_many
          next unless field_options[:header_prefix]

          size = const_get(field_options[:class_name]).map_headers_to_attributes(headers, field_options[:header_prefix])
          new_schema[field_name][:size] = size
        end
      end

      def map_headers_to_fields(headers, new_schema, header_prefix, max_size)
        new_schema.each do |field_name, field_options|
          if header_prefix
            unless (indexes = find_indexes_for_field(headers, field_options, header_prefix)).empty?
              new_schema[field_options[:alias_of] || field_name][:indexes] = indexes
              max_size = indexes.size unless max_size > indexes.size
            end
          elsif (index = headers.index(field_options[:key]))
            new_schema[field_options[:alias_of] || field_name][:index] = index
          end
        end
        max_size
      end

      def find_indexes_for_field(headers, field_options, header_prefix)
        cnt = field_options[:starting_index] || 1
        indexes = []
        # finding all headers that look like Company1Name through CompanyXName
        while (index = headers.index(header_prefix + cnt.to_s + field_options[:key]))
          cnt += 1
          indexes << index
        end
        indexes
      end
    end
  end
end
