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
      def schema
        {}.freeze
      end

      # rebuilt whenever schema is redefined, e.g. by an attribute added after the first lookup
      def schema_with_string_keys
        current_schema = schema
        return @schema_with_string_keys if @schema_with_string_keys_source.equal?(current_schema)

        @schema_with_string_keys_source = current_schema
        @schema_with_string_keys = current_schema.transform_keys(&:to_s).freeze
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
      return self if data.nil?

      update_model_attributes(data, skip_fields)
      update_associations(data, skip_fields)
      self
    end

    def as_json(opts = {})
      self.class.schema.each_with_object({}) do |(field_name, field_options), memo|
        next if field_options[:alias_of]

        value = public_send(field_options[:getter])
        next if value.nil? && !opts[:include_nils]
        next if opts[:select_filter] && !opts[:select_filter].call(field_name, value, field_options)
        next if opts[:reject_filter]&.call(field_name, value, field_options)

        memo[field_name] = value.is_a?(Array) ? value.map { |e| value_as_json(e, opts) } : value_as_json(value, opts)
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

    # values without as_json (no ActiveSupport JSON extension) are returned as is
    def value_as_json(value, opts)
      value.respond_to?(:as_json) ? value.as_json(opts) : value
    end

    # symbol keys use the schema directly, anything else is matched by its string form
    def field_options_for_key(key)
      key.is_a?(Symbol) ? self.class.schema[key] : self.class.schema_with_string_keys[key.to_s]
    end

    # names a field can be listed under in skip_fields: its name or the alias used in the data
    def skip_field_names(field_options)
      [field_options[:name], field_options[:key]].flat_map { |name| [name.to_sym, name.to_s] }
    end

    def update_model_attributes(data, skip_fields)
      data.each do |key, value|
        unless (field_options = field_options_for_key(key))
          parsing_errors.add(key, ::Schema::ParsingErrors::UNKNOWN_ATTRIBUTE) if self.class.capture_unknown_attributes?
          next
        end

        next if field_options[:association]
        next if skip_fields.intersect?(skip_field_names(field_options))

        public_send(field_options[:setter], value)
      end
    end

    def update_associations(data, skip_fields)
      data.each do |key, value|
        next unless (field_options = field_options_for_key(key))
        next unless field_options[:association]

        names = skip_field_names(field_options)
        next if skip_fields.intersect?(names)

        public_send(field_options[:setter], value, association_skip_fields(skip_fields, names))
      end
    end

    def association_skip_fields(skip_fields, names)
      skip_fields.each do |skip_field|
        next unless skip_field.is_a?(Hash)

        names.each { |name| return skip_field[name] if skip_field.key?(name) }
      end
      []
    end
  end
end
