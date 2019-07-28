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
        mapped_headers = {}
        map_headers_to_fields(headers, mapped_headers, header_prefix)
        map_headers_to_has_one_associations(headers, mapped_headers, header_prefix)
        map_headers_to_has_many_associations(headers, mapped_headers)
        mapped_headers
      end

      def get_unmapped_field_names(mapped_headers, header_prefix = nil)
        get_field_names(mapped_headers, header_prefix, false)
      end

      def get_mapped_field_names(mapped_headers, header_prefix = nil)
        get_field_names(mapped_headers, header_prefix, true)
      end

      def get_field_names(mapped_headers, header_prefix = nil, mapped = true)
        fields = []
        schema.each do |field_name, field_options|
          if field_options[:type] == :has_one
            mapped_model = mapped_headers[field_name] || {}
            fields += const_get(field_options[:class_name]).get_field_names(mapped_model, header_prefix, mapped)
          elsif field_options[:type] == :has_many
            mapped_model = mapped_headers[field_name] || {}
            fields += const_get(field_options[:class_name]).get_field_names(mapped_model, field_options[:header_prefix], mapped)
          else
            next if field_options[:alias_of]
            next if mapped == mapped_headers[field_name].nil?

            field_name = field_options[:aliases].first if field_options[:aliases]
            field_name = header_prefix + 'X' + field_name.to_s if header_prefix
            fields << field_name.to_s
          end
        end
        fields
      end

      private

      def map_headers_to_has_one_associations(headers, mapped_headers, header_prefix)
        schema.each do |field_name, field_options|
          next unless field_options[:type] == :has_one

          mapped_model = const_get(field_options[:class_name]).map_headers_to_attributes(headers, header_prefix)
          next if mapped_model.empty?

          mapped_headers[field_name] = mapped_model
        end
        mapped_headers
      end

      def map_headers_to_has_many_associations(headers, mapped_headers)
        schema.each do |field_name, field_options|
          next unless field_options[:type] == :has_many
          next unless field_options[:header_prefix]

          mapped_model = const_get(field_options[:class_name]).map_headers_to_attributes(headers, field_options[:header_prefix])
          next if mapped_model.empty?

          mapped_model[:__size] = largest_number_of_indexes_from_map(mapped_model)
          mapped_headers[field_name] = mapped_model
        end
        mapped_headers
      end

      def map_headers_to_fields(headers, mapped_headers, header_prefix)
        schema.each do |field_name, field_options|
          if header_prefix
            unless (indexes = find_indexes_for_field(headers, field_options, header_prefix)).empty?
              mapped_headers[field_options[:alias_of] || field_name] = { indexes: indexes }
            end
          elsif (index = headers.index(field_options[:key]))
            mapped_headers[field_options[:alias_of] || field_name] = { index: index }
          end
        end
        mapped_headers
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

      def largest_number_of_indexes_from_map(mapped_model)
        size = 0
        mapped_model.each do |_, info|
          if info[:indexes]
            size = info[:indexes].size if info[:indexes] && info[:indexes].size > size
          else
            new_size = largest_number_of_indexes_from_map(info)
            size = new_size if new_size > size
          end
        end
        size
      end
    end
  end
end
