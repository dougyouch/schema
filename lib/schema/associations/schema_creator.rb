# frozen_string_literal: true

module Schema
  module Associations
    # Schema::Associations::SchemaCreator is used to create schema objects for associations
    class SchemaCreator
      def initialize(base_schema, name)
        options = base_schema.class.schema[name]
        @schema_name = name
        @schema_class = base_schema.class.const_get(options[:class_name])
      end

      def create_schema(base_schema, data, error_name = nil)
        if data.is_a?(Hash)
          schema = @schema_class.from_hash(data)
          base_schema.parsing_errors.add(error_name || @schema_name, :invalid) unless schema.parsing_errors.empty?
          schema
        elsif !data.nil?
          base_schema.parsing_errors.add(error_name || @schema_name, :incompatable)
          nil
        end
      end

      def create_schemas(base_schema, list)
        if list.is_a?(Array)
          list.each_with_index.map { |data, idx| create_schema(base_schema, data, "#{idx}:#{@schema_name}") }
        elsif !list.nil?
          base_schema.parsing_errors.add(@schema_name, :incompatable)
          nil
        end
      end
    end
  end
end
