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
          types = (schema_options[:types] ||= {}).dup
          types[type] = class_name

          ::Schema::Utils.create_schema_class(
            base_schema_class,
            schema_name,
            class_name: class_name,
            base_class: self,
            types: types.freeze,
            &block
          )
        end

        private

        def schema_dynamic_type_class_name(type)
          ::Schema::Utils.classify_name(schema_name.to_s) +
            'AssociationType' +
            ::Schema::Utils.classify_name(type.to_s)
        end
      end
    end
  end
end
