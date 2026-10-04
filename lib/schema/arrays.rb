# frozen_string_literal: true

module Schema
  # Schema::Arrays maps the array to a schema model
  module Arrays
    def self.included(base)
      base.extend ClassMethods
    end

    # the fixed number of entries a has_many takes up in an array
    def self.association_size(field_options)
      field_options[:size] || raise(
        ArgumentError,
        "has_many #{field_options[:name].inspect} needs a size: option to be converted to and from arrays"
      )
    end

    # adds from_array method to the class
    module ClassMethods
      # Builds a model from a row.
      # @param array [Array] row values
      # @param mapped_headers [Hash] result of ArrayHeaders::ClassMethods#map_headers_to_attributes
      # @return [Schema::Model]
      def from_array(array, mapped_headers)
        new.update_attributes_with_array(array, mapped_headers)
      end

      # An array of nils shaped like {Schema::Arrays#to_a}'s output.
      # @return [Array]
      def to_empty_array
        data = []
        schema.each_value do |field_options|
          next if field_options[:alias_of]

          data <<
            case field_options[:type]
            when :has_one
              const_get(field_options[:class_name]).to_empty_array
            when :has_many
              Arrays.association_size(field_options).times.map { const_get(field_options[:class_name]).to_empty_array }
            end
        end
        data
      end

      # Header names in array order, e.g. `phones[1].number`.
      # @param prefix [String, nil] used internally for nested associations
      # @return [Array<String>]
      def to_headers(prefix = nil)
        headers = []
        schema.each_value do |field_options|
          next if field_options[:alias_of]

          headers <<
            case field_options[:type]
            when :has_one
              const_get(field_options[:class_name]).to_headers("#{prefix}#{field_options[:key]}.")
            when :has_many
              Arrays.association_size(field_options).times.map do |i|
                const_get(field_options[:class_name]).to_headers(prefix.to_s + field_options[:key] + "[#{i + 1}].")
              end
            else
              prefix.to_s + field_options[:key]
            end
        end
        headers.flatten
      end
    end

    # The model as a nested array, in {ClassMethods#to_headers} order; has_many entries beyond size: are left out.
    # @return [Array]
    def to_a
      data = []
      self.class.schema.each_value do |field_options|
        next if field_options[:alias_of]

        value = public_send(field_options[:getter])
        data <<
          case field_options[:type]
          when :has_one
            value ? value.to_a : self.class.const_get(field_options[:class_name]).to_empty_array
          when :has_many
            values = value || []
            Arrays.association_size(field_options).times.map do |idx|
              value = values[idx]
              value ? value.to_a : self.class.const_get(field_options[:class_name]).to_empty_array
            end
          else
            value
          end
      end
      data
    end

    # Sets attributes from a row using a header mapping.
    # @param array [Array] row values
    # @param mapped_headers [Hash] result of ArrayHeaders::ClassMethods#map_headers_to_attributes
    # @param offset [Integer, nil] has_many entry index, used internally
    # @return [self]
    def update_attributes_with_array(array, mapped_headers, offset = nil)
      self.class.schema.each_value do |field_options|
        next unless (mapped_field = mapped_headers[field_options[:name]])

        if offset
          next unless mapped_field[:indexes]
          next unless (index = mapped_field[:indexes][offset])
        else
          next unless (index = mapped_field[:index])
        end

        public_send(
          field_options[:setter],
          array[index]
        )
      end

      update_nested_schemas_from_array(array, mapped_headers, offset)

      self
    end

    # Builds nested models from a row.
    # @api private
    def update_nested_schemas_from_array(array, mapped_headers, current_offset = nil)
      update_nested_has_one_associations_from_array(array, mapped_headers, current_offset)
      update_nested_has_many_associations_from_array(array, mapped_headers)
    end

    # Builds has_one models from a row.
    # @api private
    def update_nested_has_one_associations_from_array(array, mapped_headers, current_offset = nil)
      self.class.schema.each_value do |field_options|
        next unless field_options[:type] == :has_one
        next unless (mapped_model = mapped_headers[field_options[:name]])

        instance_variable_set(
          field_options[:instance_variable],
          create_schema_with_array(field_options, array, mapped_model, current_offset)
        )
      end
    end

    # Builds has_many models from a row.
    # @api private
    def update_nested_has_many_associations_from_array(array, mapped_headers)
      self.class.schema.each_value do |field_options|
        next unless field_options[:type] == :has_many
        next unless (mapped_model = mapped_headers[field_options[:name]])

        size = largest_number_of_indexes_from_map(mapped_model)

        instance_variable_set(
          field_options[:instance_variable],
          size.times.map do |offset|
            create_schema_with_array(field_options, array, mapped_model, offset)
          end
        )
      end
    end

    # Builds one nested model from a row.
    # @api private
    def create_schema_with_array(field_options, array, mapped_model, offset)
      self.class.const_get(field_options[:class_name]).new.update_attributes_with_array(array, mapped_model, offset)
    end

    # Number of has_many entries a mapping has columns for.
    # @api private
    def largest_number_of_indexes_from_map(mapped_model)
      size = 0
      mapped_model.each_value do |info|
        if info[:indexes]
          size = info[:indexes].size if info[:indexes].size > size
        else
          new_size = largest_number_of_indexes_from_map(info)
          size = new_size if new_size > size
        end
      end
      size
    end
  end
end
