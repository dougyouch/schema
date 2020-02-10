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
          options = ::Schema::Utils.add_association_class(self, name, :has_many, options)

          code =
<<-STR
  def #{name}_schema_creator
    @#{name}_schema_creator ||= ::Schema::Associations::SchemaCreator.new(self, #{name.inspect})
  end

  def #{options[:setter]}(v)
    #{options[:instance_variable]} = #{name}_schema_creator.create_schemas(self, v)
  end
STR

          code +=
            if options[:as] == :hash
<<-STR
  def #{options[:getter]}
    #{options[:instance_variable]} ?  #{options[:instance_variable]}.values : nil
  end

  def #{options[:getter]}_as_hash
    #{options[:instance_variable]}
  end
STR
            else
<<-STR
  def #{options[:getter]}
    #{options[:instance_variable]}
  end
STR
            end

          class_eval(code, __FILE__, __LINE__ + 1)
          kls = const_get(options[:class_name])
          kls.class_eval(&block) if block
          if options[:default]
            options[:default_code] = '[]'
            ::Schema::Utils.add_association_default_methods(self, options)
          end
          add_aliases(name, options)
          kls
        end
        # rubocop:enable Naming/PredicateName
      end
    end
  end
end
