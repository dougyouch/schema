module Schema
  module Relation
    module HasOne
      def self.included base
        base.extend ClassMethods
      end

      module ClassMethods
        def has_one(name, options={}, &block)
          class_name = ::Schema::Utils.classify_name('SchemaHashOne', name.to_s)
          kls = Class.new do
            include ::Schema::Model
          end
          schema_config[:schema_includes].each do |mod|
            kls.schema_include(mod)
          end
          const_set(class_name, kls)
          kls.class_eval(&block)

          options = ::Schema::Model.default_attribute_options(name, :has_one)
                      .merge(
                        class_name: class_name
                      ).merge(options)

          add_value_to_class_method(:schema, name => options)

          class_eval(<<-STR
def #{options[:getter]}
  #{options[:instance_variable]}
end

def #{options[:setter]}(v)
  if v.is_a?(Hash)
    #{options[:instance_variable]} = #{options[:class_name]}.from_hash(v)
  elsif ! v.nil?
    errors.add(#{name.inspect}, :invalid)
  end
end
STR
                    )

          const_get(class_name)
        end
      end
    end
  end
end
