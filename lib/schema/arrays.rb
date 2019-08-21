# frozen_string_literal: true

module Schema
  # Schema::Arrays maps the array to a schema model
  module Arrays
    def self.included(base)
      base.extend ClassMethods
    end

    # adds from_array method to the class
    module ClassMethods
      def from_array(array, mapped_headers)
        new.update_attributes_with_array(array, mapped_headers)
      end

      def to_empty_array
        data = []
        schema.each do |_, field_options|
          next if field_options[:alias_of]

          data <<
            case field_options[:type]
            when :has_one
              const_get(field_options[:class_name]).to_empty_array
            when :has_many
              field_options[:size].times.map { const_get(field_options[:class_name]).to_empty_array }
            else
              nil
            end
        end
        data
      end
    end

    def to_a
      data = []
      self.class.schema.each do |_, field_options|
        next if field_options[:alias_of]

        value = public_send(field_options[:getter])
        data <<
          case field_options[:type]
          when :has_one
            value ? value.to_a : self.class.const_get(field_options[:class_name]).to_empty_array
          when :has_many
            values = value || []
            field_options[:size].times.map do |idx|
              value = values[idx]
              value ? value.to_a : self.class.const_get(field_options[:class_name]).to_empty_array
            end
          else
            value
          end
      end
      data
    end

    def update_attributes_with_array(array, mapped_headers, offset = nil)
      self.class.schema.each do |_, field_options|
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

    def update_nested_schemas_from_array(array, mapped_headers, current_offset = nil)
      update_nested_has_one_associations_from_array(array, mapped_headers, current_offset)
      update_nested_has_many_associations_from_array(array, mapped_headers)
    end

    def update_nested_has_one_associations_from_array(array, mapped_headers, current_offset = nil)
      self.class.schema.each do |_, field_options|
        next unless field_options[:type] == :has_one
        next unless (mapped_model = mapped_headers[field_options[:name]])

        instance_variable_set(
          field_options[:instance_variable],
          create_schema_with_array(field_options, array, mapped_model, current_offset)
        )
      end
    end

    def update_nested_has_many_associations_from_array(array, mapped_headers)
      self.class.schema.each do |_, field_options|
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

    def create_schema_with_array(field_options, array, mapped_model, offset)
      self.class.const_get(field_options[:class_name]).new.update_attributes_with_array(array, mapped_model, offset)
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
