# frozen_string_literal: true

module Schema
  # Schema::Utils is a collection of common utility methods used in this gem
  module Utils
    module_function

    def classify_name(name)
      name.gsub(/[^\da-z_-]/, '').gsub(/(^.|[_|-].)/) { |m| m[-1].upcase }
    end

    def create_schema_class(base_schema_class, name, options, &block)
      base_schema_class.add_value_to_class_method(:schema, name => options)
      kls = Class.new(options[:base_class] || Object) do
        @base_schema_class_name = base_schema_class.name
        def self.base_schema_class_name
          @base_schema_class_name
        end

        def self.base_schema_class
          Object.const_get(base_schema_class_name)
        end

        @schema_name = name
        def self.schema_name
          @schema_name
        end

        def self.schema_options
          base_schema_class.schema[schema_name]
        end
      end
      kls.include ::Schema::Associations::DynamicTypes if options[:type_field] || options[:external_type_field]
      base_schema_class.const_set(options[:class_name], kls)
      kls = base_schema_class.const_get(options[:class_name])

      include_schema_modules(kls, base_schema_class.schema_config) unless options[:base_class]

      kls.class_eval(&block) if block

      kls
    end

    def include_schema_modules(kls, schema_config)
      kls.include ::Schema::Model
      schema_config[:schema_includes].each do |mod|
        kls.schema_include(mod)
      end
    end

    def association_options(name, type, options)
      options[:class_name] ||= 'Schema' + classify_name(type.to_s) + classify_name(name.to_s)
      ::Schema::Model.default_attribute_options(name, type).merge(options)
    end

    def add_association_class(base_schema_class, name, type, options, &block)
      options = ::Schema::Utils.association_options(name, type, options)
      kls = ::Schema::Utils.create_schema_class(
        base_schema_class,
        name,
        options,
        &block
      )
      options
    end
  end
end
