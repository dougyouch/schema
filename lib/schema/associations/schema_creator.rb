# frozen_string_literal: true

module Schema
  module Associations
    # Schema::Associations::SchemaCreator is used to create schema objects for associations
    class SchemaCreator
      def initialize(base_schema, name)
        options = base_schema.class.schema[name]
        @schema_name = name
        @schema_class = base_schema.class.const_get(options[:class_name])
        @aliases = options[:aliases] || []
        @type_field = options[:type_field]
        @external_type_field = options[:external_type_field]
        @types = options[:types]
        @ignorecase = !options[:type_ignorecase].nil?
      end

      def create_schema(base_schema, data, error_name = nil)
        if data.is_a?(Hash)
          unless (schema_class = get_schema_class(base_schema, data))
            base_schema.parsing_errors.add(error_name || @schema_name, :unknown)
            return nil
          end
          schema = schema_class.from_hash(data)
          base_schema.parsing_errors.add(error_name || @schema_name, :invalid) unless schema.parsing_errors.empty?
          schema
        elsif !data.nil?
          base_schema.parsing_errors.add(error_name || @schema_name, :incompatable)
          nil
        end
      end

      def create_schemas(base_schema, list)
        if list.is_a?(Array)
          list.each_with_index.map { |data, idx| create_schema(base_schema, data, "#{@schema_name}:#{idx}") }
        elsif !list.nil?
          base_schema.parsing_errors.add(@schema_name, :incompatable)
          nil
        end
      end

      def get_schema_class(base_schema, data)
        if dynamic?
          get_dynamic_schema_class(base_schema, data)
        else
          @schema_class
        end
      end

      def dynamic?
        !@type_field.nil? || !@external_type_field.nil?
      end

      def get_dynamic_schema_class(base_schema, data)
        type = get_dynamic_type(base_schema, data)
        type = type.to_s.downcase if @ignorecase
        @types.each do |name, class_name|
          name = name.downcase if @ignorecase
          return base_schema.class.const_get(class_name) if name == type
        end
        nil
      end

      def get_dynamic_type(base_schema, data)
        if @type_field
          type_fields.each do |name|
            type = data[name]
            return type if type
          end
          nil
        elsif @external_type_field
          base_schema.public_send(@external_type_field)
        end
      end

      def type_fields
        @type_fields ||= [
          @type_field,
          @type_field.to_s
        ] + @aliases
      end
    end
  end
end
