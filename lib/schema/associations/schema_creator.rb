# frozen_string_literal: true

module Schema
  module Associations
    # Schema::Associations::SchemaCreator is used to create schema objects for associations
    class SchemaCreator
      include ::Schema::ParsingErrors

      def initialize(base_schema, name)
        options = base_schema.class.schema[name]
        @schema_name = name
        @schema_class = base_schema.class.const_get(options[:class_name])
        @ignorecase = options[:type_ignorecase]
        @is_list = options[:from] != :hash
        @hash_key_field = options[:hash_key_field]
        configure_dynamic_schema_options(options)
      end

      # Builds one nested model, recording parsing errors on base_schema.
      # @api private
      def create_schema(base_schema, data, error_name = nil, skip_fields = [])
        if data.is_a?(Hash)
          unless (schema_class = get_schema_class(base_schema, data))
            add_parsing_error(base_schema, error_name, UNKNOWN) if base_schema.class.capture_unknown_attributes?
            return nil
          end
          schema = schema_class.from_hash(data, skip_fields)
          add_parsing_error(base_schema, error_name, INVALID) unless schema.parsing_errors.empty?
          schema
        elsif !data.nil?
          add_parsing_error(base_schema, error_name, INCOMPATIBLE)
          nil
        end
      end

      # Builds a has_many list from an array, or from a hash with `from: :hash`.
      # @api private
      def create_schemas(base_schema, list, skip_fields = [])
        if is_list? && list.is_a?(Array)
          list.each_with_index.map { |data, idx| create_schema(base_schema, data, "#{@schema_name}:#{idx}", skip_fields) }
        elsif !is_list? && list.is_a?(Hash)
          list.map do |(key, data)|
            schema = create_schema(base_schema, data, "#{@schema_name}:#{key}", skip_fields)
            schema&.public_send(schema.class.schema[@hash_key_field][:setter], key)
            schema
          end
        elsif !list.nil?
          add_parsing_error(base_schema, @schema_name, INCOMPATIBLE)
          nil
        end
      end

      # The class to build for data, choosing a dynamic type when configured.
      # @api private
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

      def is_list?
        @is_list
      end

      # The dynamic type class matching data's type.
      # @api private
      def get_dynamic_schema_class(base_schema, data)
        type = get_dynamic_type(base_schema, data)
        type = type.to_s.downcase if @ignorecase
        @types.each do |name, class_name|
          name = name.downcase if @ignorecase
          return base_schema.class.const_get(class_name) if name == type
        end
        get_default_dynamic_schema_class(base_schema)
      end

      # The default_type class, if one was declared.
      # @api private
      def get_default_dynamic_schema_class(base_schema)
        return unless (class_name = @types[:default])

        base_schema.class.const_get(class_name)
      end

      # The type value from the nested data or the parent's external type field.
      # @api private
      def get_dynamic_type(base_schema, data)
        if @type_field
          type_fields.each do |name|
            type = data[name]
            return type if type
          end
          nil
        else
          base_schema.public_send(@external_type_field)
        end
      end

      # the type field and its attribute aliases, as symbols and strings
      def type_fields
        @type_fields ||= begin
          aliases = @schema_class.schema.dig(@type_field.to_sym, :aliases) || []
          [@type_field, *aliases].flat_map { |name| [name.to_sym, name.to_s] }.uniq
        end
      end

      # Records a parsing error on the parent model.
      # @api private
      def add_parsing_error(base_schema, error_name, error_msg)
        base_schema.parsing_errors.add(error_name || @schema_name, error_msg)
      end

      # Reads the dynamic type options.
      # @api private
      def configure_dynamic_schema_options(options)
        @type_field = options[:type_field]
        @external_type_field = options[:external_type_field]
        @types = options[:types]
      end
    end
  end
end
