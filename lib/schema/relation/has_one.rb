module Schema
  module Relation
    module HasOne
      def self.included base
        base.extend ClassMethods
      end

      def self.classify_name(base, name)
        base + name.gsub(/(^.|_.)/) { |m| m[-1].upcase }
      end

      module ClassMethods
        def has_one(name, options={}, &block)
          class_name = HasOne.class_name('SchemaHashOne', name.to_s)
          kls = Class.new do
            include ::Schema::Model
          end
          schema_config[:schema_includes].each do |mod|
            kls.schema_include(mod)
          end
          const_set(class_name, kls)
          kls.class_eval(&block)
          const_get(class_name)
        end
      end

      def schema_set_has_one(name, value)
      end
    end
  end
end
