# frozen_string_literal: true

module Schema
  module Relation
    # Schema::Relation::HasMany is used to create a list nested schema objects
    module HasMany
      def self.included(base)
        base.extend ClassMethods
      end

      # no-doc
      module ClassMethods
        # rubocop:disable Naming/PredicateName
        def has_many(name, options = {}, &block)
          _, class_name = ::Schema::Utils.create_schema_class(self, 'SchemaHasMany', name, &block)

          options = ::Schema::Model.default_attribute_options(name, :has_many)
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
                if schemas = ::Schema::Utils.create_schemas(self, #{options[:class_name]}, #{name.inspect}, v)
                  #{options[:instance_variable]} = schemas
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
