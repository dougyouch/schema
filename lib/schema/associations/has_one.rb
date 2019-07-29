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
          options = ::Schema::Utils.add_association_class(self, name, :has_one, options, &block)

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

          const_get(options[:class_name])
        end
        # rubocop:enable Naming/PredicateName
      end
    end
  end
end
