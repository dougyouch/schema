module Schema
  module Arrays
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def from_array(array)
        new.update_attributes_with_array(array)
      end
    end

    def update_attributes_with_array(array)
      self.class.schema.each do |_, field_options|
        next unless index = field_options[:index]

        public_send(
          field_options[:setter],
          array[index]
        )
      end

      update_nested_schemas_from_array(array)

      self
    end

    def update_attributes_with_array_from_offset(offset, array)
      self.class.schema.each do |_, field_options|
        next unless field_options[:indexes]
        next unless index = field_options[:indexes][offset]

        public_send(
          field_options[:setter],
          array[index]
        )
      end

      update_nested_schemas_from_array(array)

      self
    end

    def update_nested_schemas_from_array(array)
      self.class.schema.each do |_, field_options|
        next unless field_options[:type] == :has_one

        instance_variable_set(
          field_options[:instance_variable],
          self.class.const_get(field_options[:class_name]).new.update_attributes_with_array(array)
        )
      end

      self.class.schema.each do |_, field_options|
        next unless field_options[:type] == :has_many

        instance_variable_set(
          field_options[:instance_variable],
          field_options[:size].times.map do |offset|
            self.class.const_get(field_options[:class_name]).new.update_attributes_with_array_from_offset(offset, array)
          end
        )
      end
    end
  end
end
