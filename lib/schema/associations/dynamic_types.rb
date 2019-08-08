# frozen_string_literal: true

module Schema
  module Associations
    # Schema::Associations::DynamicTypes adds support for adding dynamic types to associations
    module DynamicTypes
      def self.included(base)
        base.extend ClassMethods
      end

      # no-doc
      module ClassMethods
        def add_type(type, options = {}, &block)
          class_name = options[:class_name] || schema_dynamic_type_class_name(type)
          kls = Class.new(self)
          kls = base_schema_class.const_set(class_name, kls)
          schema_add_dynamic_type(type, class_name)
          kls.class_eval(&block) if block
          kls
        end

        def default_type(options = {}, &block)
          add_type(:default, options, &block)
        end

        def dynamic_types
          schema_options[:types]
        end

        def dynamic_type_names
          dynamic_types.keys - [:default]
        end

        private

        def schema_dynamic_type_class_name(type)
          ::Schema::Utils.classify_name(schema_name.to_s) +
            'AssociationType' +
            ::Schema::Utils.classify_name(type.to_s)
        end

        def schema_add_dynamic_type(type, class_name)
          new_schema_options = schema_options.dup
          new_schema_options[:types] ||= {}
          new_schema_options[:types][type] = class_name
          base_schema_class.add_value_to_class_method(:schema, schema_name => new_schema_options)
          new_schema_options
        end
      end
    end
  end
end
