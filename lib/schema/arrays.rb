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

        instance_variable_set(
          field_options[:instance_variable],
          mapped_model[:__size].times.map do |offset|
            create_schema_with_array(field_options, array, mapped_model, offset)
          end
        )
      end
    end

    def create_schema_with_array(field_options, array, mapped_model, offset)
      self.class.const_get(field_options[:class_name]).new.update_attributes_with_array(array, mapped_model, offset)
    end
  end
end
