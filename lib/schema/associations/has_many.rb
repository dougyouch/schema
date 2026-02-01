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
        def has_many(name, options = {}, &block)
          options = ::Schema::Utils.add_association_class(self, name, :has_many, options)

          class_eval(
            <<-STR, __FILE__, __LINE__ + 1
  def #{options[:getter]}
    #{options[:instance_variable]}
  end

  def #{name}_schema_creator
    @#{name}_schema_creator ||= ::Schema::Associations::SchemaCreator.new(self, #{name.inspect})
  end

  def #{options[:setter]}(v, skip_fields = [])
    #{options[:instance_variable]} = #{name}_schema_creator.create_schemas(self, v, skip_fields)
  end

  def append_to_#{options[:getter]}(v, skip_fields = [])
    #{options[:instance_variable]} ||= []
    #{options[:instance_variable]} << #{name}_schema_creator.create_schema(self, v, nil, skip_fields)
  end
            STR
          )

          kls = const_get(options[:class_name])
          kls.class_eval(&block) if block
          if options[:default]
            options[:default_code] = '[]'
            ::Schema::Utils.add_association_default_methods(self, options)
          end
          add_aliases(name, options)
          kls
        end
      end
    end
  end
end
