# frozen_string_literal: true

require 'inheritance-helper'

module Schema
  module Model
    def self.included(base)
      base.extend InheritanceHelper::Methods
      base.include Schema::Parsers::Common
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

    module ClassMethods
      def schema
        {}.freeze
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

        class_eval(<<~STR
          def #{options[:getter]}
            #{options[:instance_variable]}
          end

          def #{options[:setter]}(v)
            #{options[:instance_variable]} = #{options[:parser]}(#{name.inspect}, parsing_errors, v)
          end
        STR
                  )

        options[:aliases]&.each do |alias_name|
          add_value_to_class_method(:schema, alias_name.to_sym => options.merge(key: alias_name.to_s, alias_of: name))
          alias_method(alias_name, options[:getter])
          alias_method("#{alias_name}=", options[:setter])
        end
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

      def schema_base_class=(kls)
        config = schema_config.dup
        config[:schema_base_class] = kls
        redefine_class_method(:schema_config, config.freeze)
      end

      def set_schema_base_class_to_superclass
        self.schema_base_class = superclass
      end
    end

    def update_attributes(data)
      self.class.schema.each do |field_name, field_options|
        next if !data.key?(field_options[:key]) && !data.key?(field_name)

        public_send(
          field_options[:setter],
          data[field_options[:key]] || data[field_name.to_sym]
        )
      end

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
      @parsing_errors ||= ::Schema::Errors.new
    end
  end
end
