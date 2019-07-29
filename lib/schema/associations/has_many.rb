# frozen_string_literal: true

module Schema
  module Associations
    # Schema::Associations::HasMany is used to create a list nested schema objects
    module HasMany
      def self.included(base)
        base.extend ClassMethods
      end

      # no-doc
      module ClassMethods
        # rubocop:disable Naming/PredicateName
        def has_many(name, options = {}, &block)
          options = ::Schema::Utils.add_association_class(self, name, :has_many, options, &block)

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

          const_get(options[:class_name])
        end
        # rubocop:enable Naming/PredicateName
      end
    end
  end
end
