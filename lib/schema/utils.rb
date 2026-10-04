# frozen_string_literal: true

module Schema
  # Schema::Utils is a collection of common utility methods used in this gem
  module Utils
    module_function

    def check_parser!(model, parser, field_name, type)
      return if model.respond_to?(parser)

      raise ::Schema::UnknownTypeError,
            "unknown type #{type.inspect} for #{model.class.name || model.class}##{field_name}: " \
            "no #{parser} method (schema_include the parser module that defines it)"
    end

    def classify_name(name)
      name.gsub(/[^\da-z_-]/, '').gsub(/(^.|[_|-].)/) { |m| m[-1].upcase }
    end

    def create_schema_class(base_schema_class, schema_name, options)
      base_schema_class.add_value_to_class_method(:schema, schema_name => options)
      kls = Class.new(options[:base_class] || Object)
      kls = base_schema_class.const_set(options[:class_name], kls)
      include_schema_modules(kls, base_schema_class.schema_config) unless options[:base_class]
      kls.capture_unknown_attributes = base_schema_class.capture_unknown_attributes?
      kls
    end

    def include_schema_modules(kls, schema_config)
      kls.send(:include, ::Schema::Model)
      schema_config[:schema_includes].each do |mod|
        kls.schema_include(mod)
      end
    end

    def association_options(schema_name, schema_type, options)
      options[:class_name] ||= "Schema#{classify_name(schema_type.to_s)}#{classify_name(schema_name.to_s)}"
      options[:association] = true
      options[:aliases] = [options[:alias]] if options.key?(:alias)
      options[:hash_key_field] ||= :id if options[:from] == :hash
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
      kls.send(:include, ::Schema::Associations::Base)
      kls.base_schema_class = base_schema_class
      kls.schema_name = schema_name
    end

    def add_association_dynamic_types(kls, options)
      return if !options[:type_field] && !options[:external_type_field]

      kls.send(:include, ::Schema::Associations::DynamicTypes)
    end

    # copies nested models and collections so the copy can be changed without touching the original
    def deep_dup_value(value)
      case value
      when ::Schema::Model then value.deep_dup
      when ::Array then value.map { |element| deep_dup_value(element) }
      when ::Hash then value.to_h { |key, element| [key, deep_dup_value(element)] }
      when ::String then value.frozen? ? value : value.dup
      else value
      end
    end

    # [attribute, message] pairs from Schema::Errors or ActiveModel::Errors
    def parsing_error_pairs(errors)
      return errors.map { |error| [error.attribute, error.message] } unless errors.is_a?(::Schema::Errors)

      errors.errors.flat_map { |attribute, messages| messages.map { |message| [attribute, message] } }
    end

    # each call gets its own copy so callers can't mutate the shared default
    def copy_default(value)
      return value if value.frozen?

      Marshal.load(Marshal.dump(value))
    rescue TypeError
      value.dup
    end

    def add_attribute_default_methods(kls, options)
      default = options[:default]
      kls.send(:define_method, options[:default_method]) { ::Schema::Utils.copy_default(default) }
      kls.class_eval(
        <<-STR, __FILE__, __LINE__ + 1
  def #{options[:getter]}
    if #{options[:instance_variable]}.nil?
      #{options[:default_method]}
    else
      #{options[:instance_variable]}
    end
  end
        STR
      )
    end

    def add_association_default_methods(kls, options)
      kls.class_eval(
        <<-STR, __FILE__, __LINE__ + 1
  def #{options[:default_method]}
    #{options[:default_code]}
  end

  def #{options[:getter]}
    #{options[:instance_variable]} ||= #{options[:default_method]}
  end
        STR
      )
    end
  end
end
