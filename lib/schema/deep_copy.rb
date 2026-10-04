# frozen_string_literal: true

module Schema
  # Schema::DeepCopy copies a model along with its nested models, collections and parsing errors
  module DeepCopy
    # Copies the model with its nested models, collections, strings and parsing errors,
    # so the copy can be changed without touching the original.
    # @return [Schema::Model]
    def deep_dup
      copy = dup
      copy.copy_attribute_values_from(self)
      copy.copy_parsing_errors_from(self)
      copy
    end

    protected

    def copy_attribute_values_from(source)
      self.class.schema.each_value do |field_options|
        next if field_options[:alias_of]

        copy_instance_variable_from(source, field_options[:instance_variable])
        next unless field_options[:association] && field_options[:default]

        copy_instance_variable_from(source, ::Schema::Utils.association_default_instance_variable(field_options))
      end
    end

    def copy_instance_variable_from(source, ivar)
      return unless source.instance_variable_defined?(ivar)

      instance_variable_set(ivar, ::Schema::Utils.deep_dup_value(source.instance_variable_get(ivar)))
    end

    def copy_parsing_errors_from(source)
      @parsing_errors = nil
      ::Schema::Utils.parsing_error_pairs(source.parsing_errors).each do |attribute, message|
        parsing_errors.add(attribute, message)
      end
    end
  end
end
