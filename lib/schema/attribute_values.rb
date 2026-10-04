# frozen_string_literal: true

module Schema
  # Schema::AttributeValues compares and inspects models by their attribute values
  module AttributeValues
    # every attribute (aliases excluded) and its current value, defaults included
    def attribute_values
      self.class.schema.each_with_object({}) do |(field_name, field_options), values|
        next if field_options[:alias_of]

        values[field_name] = public_send(field_options[:getter])
      end
    end

    def ==(other)
      other.instance_of?(self.class) && other.attribute_values == attribute_values
    end

    # lists the attributes that were set, e.g. #<UserSchema name: "Joe", age: 30>
    def inspect
      details = set_field_options.map do |field_options|
        "#{field_options[:name]}: #{public_send(field_options[:getter]).inspect}"
      end
      "#<#{self.class.name || self.class}#{" #{details.join(', ')}" unless details.empty?}>"
    end

    private

    def set_field_options
      self.class.schema.each_value.select do |field_options|
        !field_options[:alias_of] && instance_variable_defined?(field_options[:instance_variable])
      end
    end
  end
end
