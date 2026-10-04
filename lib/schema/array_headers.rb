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
          next if field_options[:alias_of]

          if field_options[:association]
            fields += get_model_field_names(field_name, field_options, mapped_headers, header_prefix, mapped)
          else
            next if skip_field?(field_name, mapped_headers, mapped)

            fields << generate_field_name(field_name, field_options, header_prefix)
          end
        end
        fields
      end

      MAX_ARRAY_INDEX = 10_000

      private

      # has_many columns are reported as <prefix>X<field>; has_one fields share the parent's prefix
      def get_model_field_names(field_name, field_options, mapped_headers, header_prefix, mapped)
        mapped_model = mapped_headers[field_name] || {}
        header_prefix ||= (field_options[:aliases]&.first || field_name).to_s if field_options[:type] == :has_many
        const_get(field_options[:class_name]).get_field_names(mapped_model, header_prefix, mapped)
      end

      def skip_field?(field_name, mapped_headers, mapped)
        if mapped
          mapped_headers[field_name].nil?
        else
          !mapped_headers[field_name].nil?
        end
      end

      def generate_field_name(field_name, field_options, header_prefix)
        field_name = field_options[:aliases].first if field_options[:aliases]
        field_name = "#{header_prefix}X#{field_name}" if header_prefix
        field_name.to_s
      end

      def get_mapped_model(field_options, headers, header_prefix)
        const_get(field_options[:class_name]).map_headers_to_attributes(headers, header_prefix)
      end

      # a column already claimed by the parent (or an earlier has_one) isn't reused for a nested field
      def map_headers_to_has_one_associations(headers, mapped_headers, header_prefix)
        claimed_indexes = mapped_header_indexes(mapped_headers)
        schema.each do |field_name, field_options|
          next unless field_options[:type] == :has_one
          # aliases are matched through the association's own entry
          next if field_options[:alias_of]

          available_headers = headers.each_with_index.map { |header, idx| claimed_indexes.include?(idx) ? nil : header }
          mapped_model = get_mapped_model(field_options, available_headers, header_prefix)
          next if mapped_model.empty?

          mapped_headers[field_name] = mapped_model
          claimed_indexes.concat(mapped_header_indexes(mapped_model))
        end
        mapped_headers
      end

      def mapped_header_indexes(mapped_headers)
        mapped_headers.each_value.flat_map do |info|
          if info.key?(:index)
            [info[:index]]
          elsif info.key?(:indexes)
            info[:indexes]
          else
            mapped_header_indexes(info)
          end
        end
      end

      def map_headers_to_has_many_associations(headers, mapped_headers)
        schema.each do |field_name, field_options|
          next unless field_options[:type] == :has_many
          next if field_options[:alias_of]

          get_header_prefixes(field_name, field_options).each do |header_prefix|
            mapped_model = get_mapped_model(field_options, headers, header_prefix)
            next if mapped_model.empty?

            mapped_headers[field_name] = mapped_model
            break
          end
        end
        mapped_headers
      end

      def map_headers_to_fields(headers, mapped_headers, header_prefix)
        schema.each do |field_name, field_options|
          # associations are mapped through their nested fields, not a column of their own
          next if field_options[:association]

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
        while cnt <= MAX_ARRAY_INDEX && (index = headers.index(header_prefix + cnt.to_s + field_options[:key]))
          indexes << index
          cnt += 1
        end
        indexes
      end

      def get_header_prefixes(field_name, field_options)
        names = [field_name.to_s]
        names += field_options[:aliases] if field_options[:aliases]
        names
      end
    end
  end
end
