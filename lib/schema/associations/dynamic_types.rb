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
          class_name = options[:class_name] || 'AssociationType' + ::Schema::Utils.classify_name(type.to_s)
          kls = ::Schema::Utils.create_schema_class(self, type, class_name: class_name, base_class: self, &block)
          schema_options = self.schema_options.dup
          types = (schema_options[:types] ||= {}).dup
          types[type] = kls
          types.freeze
          schema_options[:types] = types
          self.base_schema_class.add_value_to_class_method(:schema, self.schema_name => schema_options)
          kls
        end
      end
    end
  end
end
