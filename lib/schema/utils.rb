# frozen_string_literal: true

module Schema
  # Schema::Utils is a collection of common utility methods used in this gem
  module Utils
    module_function

    def classify_name(name)
      name.gsub(/[^\da-z_-]/, '').gsub(/(^.|[_|-].)/) { |m| m[-1].upcase }
    end

    def create_schema_class(base_schema_class, class_name, base_class, &block)
      schema_config = base_schema_class.schema_config
      kls = Class.new(base_class) do
        include ::Schema::Model
      end

      base_schema_class.const_set(class_name, kls)
      kls = base_schema_class.const_get(class_name)

      if base_class == Object
        schema_config[:schema_includes].each do |mod|
          kls.schema_include(mod)
        end
      end

      kls.class_eval(&block)

      [kls, class_name]
    end

    def create_schema(base_schema, schema_class, schema_name, data)
      if data.is_a?(Hash)
        schema = schema_class.from_hash(data)
        base_schema.parsing_errors.add(schema_name, :invalid) unless schema.parsing_errors.empty?
        schema
      elsif !data.nil?
        base_schema.parsing_errors.add(schema_name, :incompatable)
        nil
      end
    end

    def create_schemas(base_schema, schema_class, schema_name, list)
      if list.is_a?(Array)
        list.each_with_index.map { |data, idx| create_schema(base_schema, schema_class, "#{idx}:#{schema_name}", data) }
      elsif !list.nil?
        base_schema.parsing_errors.add(schema_name, :incompatable)
        nil
      end
    end

    def association_options(name, type, options)
      options[:class_name] ||= 'Schema' + classify_name(type.to_s) + classify_name(name.to_s)
      ::Schema::Model.default_attribute_options(name, type).merge(options)
    end

    def add_association_class(base_schema_class, name, type, options, &block)
      options = ::Schema::Utils.association_options(name, type, options)
      ::Schema::Utils.create_schema_class(
        base_schema_class,
        options[:class_name],
        options[:base_class] || Object,
        &block
      )
      base_schema_class.add_value_to_class_method(:schema, name => options)
      options
    end
  end
end
