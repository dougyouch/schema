# frozen_string_literal: true

module Schema
  # Schema::Utils is a collection of common utility methods used in this gem
  module Utils
    module_function

    def classify_name(name)
      name.gsub(/[^\da-z_-]/, '').gsub(/(^.|[_|-].)/) { |m| m[-1].upcase }
    end

    def create_schema_class(base_schema_class, class_name, base_class, &block)
      kls = Class.new(base_class)
      base_schema_class.const_set(class_name, kls)
      kls = base_schema_class.const_get(class_name)

      include_schema_modules(kls, base_schema_class.schema_config) if base_class == Object

      kls.class_eval(&block) if block

      kls
    end

    def include_schema_modules(kls, schema_config)
      kls.include ::Schema::Model
      schema_config[:schema_includes].each do |mod|
        kls.schema_include(mod)
      end
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

    def create_dynamic_schema(base_schema, schema_name, data, error_name = nil)
      if data.is_a?(Hash)
        options = base_schema.class.schema[schema_name]

        type = get_dynamic_type(
          base_schema,
          data,
          options[:type_field],
          options[:external_type_field],
          get_dynamic_type_aliases(options)
        )
        return nil unless type

        unless (schema_class = get_dynamic_schema_class(type, options[:types], options[:type_ignorecase]))
          base_schema.parsing_errors.add(error_name || schema_name, :unknown)
          return nil
        end

        create_schema(base_schema, schema_class, schema_name, data)
      elsif !data.nil?
        base_schema.parsing_errors.add(error_name || schema_name, :incompatable)
        nil
      end
    end

    def create_dynamic_schemas(base_schema, schema_name, list)
      if list.is_a?(Array)
        list.each_with_index.map do |data, idx|
          create_dynamic_schema(base_schema, schema_name, data, "#{idx}:#{schema_name}")
        end
      elsif !list.nil?
        base_schema.parsing_errors.add(schema_name, :incompatable)
        nil
      end
    end

    def get_dynamic_schema_class(type, types, ignorecase)
      type = type.to_s.downcase if ignorecase
      types.each do |name, kls|
        if ignorecase
          return kls if name.downcase == type
        elsif name == type
          return kls
        end
      end
      nil
    end

    def get_dynamic_type(base_schema, data, type_field, external_type_field, aliases)
      if type_field
        type = data[type_field] || data[type_field.to_s]
        return type if type

        if aliases
          aliases.each do |alias_name|
            next unless (type = data[alias_name])
            return type
          end
        end
        nil
      elsif external_type_field
        base_schema.public_send(external_type_field)
      end
    end

    def get_dynamic_type_aliases(options)
      return unless options[:type_field]

      options[:types].values.first.schema[options[:type_field]][:aliases]
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
