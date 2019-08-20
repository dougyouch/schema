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
        instance_variable: "@#{name}"
      }
    end

    # no-doc
    module ClassMethods
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
          schema_includes: []
        }.freeze
      end

      def attribute(name, type, options = {})
        options[:aliases] = [options[:alias]] if options.key?(:alias)

        options = ::Schema::Model.default_attribute_options(name, type)
                                 .merge(
                                   parser: "parse_#{type}"
                                 ).merge(options)

        add_value_to_class_method(:schema, name => options)
        add_attribute_methods(name, options)
        add_aliases(name, options)
      end

      def from_hash(data)
        new.update_attributes(data)
      end

      def schema_include(mod)
        config = schema_config.dup
        config[:schema_includes] = config[:schema_includes] + [mod]
        redefine_class_method(:schema_config, config.freeze)
        include mod
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

    def update_attributes(data)
      schema = get_schema(data)
      update_model_attributes(schema, data)
      update_associations(schema, data)
      self
    end

    def as_json(opts = {})
      self.class.schema.each_with_object({}) do |(field_name, field_options), memo|
        unless field_options[:alias_of]
          value = public_send(field_options[:getter])
          memo[field_name] = value if !value.nil? || opts[:include_nils]
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
      data.each_key do |key|
        break unless key.is_a?(Symbol)

        return self.class.schema
      end
      self.class.schema_with_string_keys
    end

    def update_model_attributes(schema, data)
      data.each do |key, value|
        unless schema.key?(key)
          parsing_errors.add(key, ::Schema::ParsingErrors::UNKNOWN_ATTRIBUTE)
          next
        end

        next if schema[key][:association]

        public_send(schema[key][:setter], value)
      end
    end

    def update_associations(schema, data)
      data.each do |key, value|
        next unless schema.key?(key)
        next unless schema[key][:association]

        public_send(schema[key][:setter], value)
      end
    end
  end
end
