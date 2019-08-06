# frozen_string_literal: true

module Schema
  # Schema::Utils is a collection of common utility methods used in this gem
  module Utils
    module_function

    def classify_name(name)
      name.gsub(/[^\da-z_-]/, '').gsub(/(^.|[_|-].)/) { |m| m[-1].upcase }
    end

    def create_schema_class(base_schema_class, schema_name, options)
      base_schema_class.add_value_to_class_method(:schema, schema_name => options)
      kls = Class.new(options[:base_class] || Object)
      kls = base_schema_class.const_set(options[:class_name], kls)
      include_schema_modules(kls, base_schema_class.schema_config) unless options[:base_class]
      kls
    end

    def include_schema_modules(kls, schema_config)
      kls.include ::Schema::Model
      schema_config[:schema_includes].each do |mod|
        kls.schema_include(mod)
      end
    end

    def association_options(schema_name, schema_type, options)
      options[:class_name] ||= 'Schema' + classify_name(schema_type.to_s) + classify_name(schema_name.to_s)
      ::Schema::Model.default_attribute_options(schema_name, schema_type).merge(options)
    end

    def add_association_class(base_schema_class, schema_name, schema_type, options)
      options = ::Schema::Utils.association_options(schema_name, schema_type, options)
      kls = ::Schema::Utils.create_schema_class(
        base_schema_class,
        schema_name,
        options
      )
      add_association_defaults(kls, base_schema_class, schema_name)
      add_association_dynamic_types(kls, options)
      options
    end

    def add_association_defaults(kls, base_schema_class, schema_name)
      kls.include ::Schema::Associations::Base
      kls.base_schema_class = base_schema_class
      kls.schema_name = schema_name
    end

    def add_association_dynamic_types(kls, options)
      return if !options[:type_field] && !options[:external_type_field]

      kls.include ::Schema::Associations::DynamicTypes
    end
  end
end
