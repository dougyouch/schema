# frozen_string_literal: true

module Schema
  module Associations
    # Schema::Associations::Base common class methods between associations
    module Base
      def self.included(base)
        base.extend ClassMethods
      end

      # no-doc
      module ClassMethods
        attr_accessor :schema_name

        def base_schema_class=(kls)
          @base_schema_class_name = kls.name
        end

        def base_schema_class
          Object.const_get(@base_schema_class_name)
        end

        def schema_options
          base_schema_class.schema[schema_name]
        end
      end
    end
  end
end
