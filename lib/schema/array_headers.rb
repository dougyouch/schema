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

      def get_model_field_names(field_name, field_options, mapped_headers, header_prefix, mapped)
        mapped_model = mapped_headers[field_name] || {}
        const_get(field_options[:class_name]).get_field_names(
          mapped_model,
          header_prefix || field_options[:aliases]&.first,
          mapped
        )
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

      def map_headers_to_has_one_associations(headers, mapped_headers, header_prefix)
        schema.each do |field_name, field_options|
          next unless field_options[:type] == :has_one

          mapped_model = get_mapped_model(field_options, headers, header_prefix)
          next if mapped_model.empty?

          mapped_headers[field_name] = mapped_model
        end
        mapped_headers
      end

      def map_headers_to_has_many_associations(headers, mapped_headers)
        schema.each do |field_name, field_options|
          next unless field_options[:type] == :has_many

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
