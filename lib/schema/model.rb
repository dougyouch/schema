# frozen_string_literal: true

require 'inheritance-helper'

module Schema
  # Schema::Model adds schema building methods to a class
  module Model
    def self.included(base)
      base.extend InheritanceHelper::Methods
      base.send(:include, Schema::Parsers::Common)
      base.extend ClassMethods
    end

    def self.default_attribute_options(name, type)
      {
        key: name.to_s.freeze,
        name: name,
        type: type,
        getter: name.to_s.freeze,
        setter: "#{name}=",
        instance_variable: "@#{name}",
        default_method: "#{name}_default"
      }
    end

    # no-doc
    module ClassMethods
      def self.include(base)
        base.capture_unknown_attributes = true
      end

      def schema
        {}.freeze
      end

      def schema_with_string_keys
        @schema_with_string_keys ||=
          begin
            hsh = {}
            schema.each { |field_name, field_options| hsh[field_name.to_s] = field_options }
            hsh.freeze
          end
      end

      def schema_config
        {
          schema_includes: [],
          capture_unknown_attributes: true
        }.freeze
      end

      def capture_unknown_attributes=(v)
        config = schema_config.dup
        config[:capture_unknown_attributes] = v
        redefine_class_method(:schema_config, config.freeze)
      end

      def capture_unknown_attributes?
        schema_config[:capture_unknown_attributes]
      end

      def attribute(name, type, options = {})
        options[:aliases] = [options[:alias]] if options.key?(:alias)

        options = ::Schema::Model.default_attribute_options(name, type)
                                 .merge(
                                   parser: "parse_#{type}"
                                 ).merge(options)

        add_value_to_class_method(:schema, name => options)
        add_attribute_methods(name, options)
        ::Schema::Utils.add_attribute_default_methods(self, options) if options.key?(:default)
        add_aliases(name, options)
      end

      def from_hash(data = nil, skip_fields = [])
        new.update_attributes(data, skip_fields)
      end

      def schema_include(mod)
        config = schema_config.dup
        config[:schema_includes] = config[:schema_includes] + [mod]
        redefine_class_method(:schema_config, config.freeze)
        include mod

        schema.each_value do |field_options|
          next unless field_options[:association]

          const_get(field_options[:class_name]).schema_include(mod)
        end
      end

      def add_attribute_methods(name, options)
        class_eval(
          <<-STR, __FILE__, __LINE__ + 1
  def #{options[:getter]}
    #{options[:instance_variable]}
  end

  def #{options[:setter]}(v)
    #{options[:instance_variable]} = #{options[:parser]}(#{name.inspect}, parsing_errors, v)
  end

  def #{options[:getter]}_was_set?
    instance_variable_defined?(:#{options[:instance_variable]})
  end
          STR
        )
      end

      def add_aliases(name, options)
        return unless options[:aliases]

        options[:aliases].each do |alias_name|
          add_value_to_class_method(:schema, alias_name.to_sym => options.merge(key: alias_name.to_s, alias_of: name))
          alias_method(alias_name, options[:getter])
          alias_method("#{alias_name}=", options[:setter])
        end
      end
    end

    def update_attributes(data = nil, skip_fields = [])
      schema = get_schema(data)
      update_model_attributes(schema, data, skip_fields)
      update_associations(schema, data, skip_fields)
      self
    end

    def as_json(opts = {})
      self.class.schema.each_with_object({}) do |(field_name, field_options), memo|
        next if field_options[:alias_of]

        value = public_send(field_options[:getter])
        next if value.nil? && !opts[:include_nils]
        next if opts[:select_filter] && !opts[:select_filter].call(field_name, value, field_options)
        next if opts[:reject_filter]&.call(field_name, value, field_options)

        memo[field_name] = if value.is_a?(Array)
                             value.map { |e| e.as_json(opts) }
                           else
                             value.respond_to?(:as_json) ? value.as_json(opts) : value
                           end
      end
    end

    def to_hash
      as_json(include_nils: true)
    end
    alias to_h to_hash

    def parsing_errors
      @parsing_errors ||= Errors.new
    end

    def not_set?
      self.class.schema.values.all? do |field_options|
        !instance_variable_defined?(field_options[:instance_variable])
      end
    end

    private

    def get_schema(data)
      first_key = data.each_key.first
      return self.class.schema_with_string_keys unless first_key.is_a?(Symbol)

      self.class.schema
    end

    def update_model_attributes(schema, data, skip_fields)
      data.each do |key, value|
        unless schema.key?(key)
          parsing_errors.add(key, ::Schema::ParsingErrors::UNKNOWN_ATTRIBUTE) if self.class.capture_unknown_attributes?
          next
        end

        next if schema[key][:association]
        next if skip_fields.include?(key)

        public_send(schema[key][:setter], value)
      end
    end

    def update_associations(schema, data, skip_fields)
      data.each do |key, value|
        next unless schema.key?(key)
        next unless schema[key][:association]

        association_skip_fields = skip_fields.detect { |f| f.is_a?(Hash) && f.include?(key) }
        association_skip_fields = association_skip_fields ? association_skip_fields[key] : []
        public_send(schema[key][:setter], value, association_skip_fields)
      end
    end
  end
end
