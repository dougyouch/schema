# frozen_string_literal: true

module Schema
  module Associations
    # Schema::Associations::HasOne is used to create a nested schema object
    module HasOne
      def self.included(base)
        base.extend ClassMethods
      end

      # no-doc
      module ClassMethods
        # rubocop:disable Naming/PredicateName
        def has_one(name, options = {}, &block)
          _, class_name = ::Schema::Utils.create_schema_class(self, 'SchemaHasOne', name, &block)

          options = ::Schema::Model.default_attribute_options(name, :has_one)
                                   .merge(
                                     class_name: class_name
                                   ).merge(options)

          add_value_to_class_method(:schema, name => options)

          class_eval(
            <<~STR, __FILE__, __LINE__ + 1
              def #{options[:getter]}
                #{options[:instance_variable]}
              end

              def #{options[:setter]}(v)
                if schema = ::Schema::Utils.create_schema(self, #{options[:class_name]}, #{name.inspect}, v)
                  #{options[:instance_variable]} = schema
                end
              end
          STR
          )

          const_get(class_name)
        end
        # rubocop:enable Naming/PredicateName
      end
    end
  end
end
