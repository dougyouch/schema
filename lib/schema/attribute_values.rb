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

    # only the attributes and associations present in the input (including ones set to nil),
    # e.g. the fields a PATCH request sent
    def set_attribute_values
      set_field_options.to_h { |field_options| [field_options[:name], public_send(field_options[:getter])] }
    end

    # @param other [Object]
    # @return [Boolean] true for a model of the same class with equal attribute values
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
