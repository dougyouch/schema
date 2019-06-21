module Schema
  module Utils
    extend self

    def classify_name(base, name)
      base + name.gsub(/[^\da-z_-]/, '').gsub(/(^.|[_|-].)/) { |m| m[-1].upcase }
    end

    def create_schema_class(schema_class, base_class_name, name, &block)
      schema_config = schema_class.schema_config
      kls = Class.new(schema_config[:schema_base_class] || Object) do
        include ::Schema::Model
      end

      # make sure additional schema classes use this base class
      kls.schema_base_class = schema_config[:schema_base_class] if schema_config[:schema_base_class]

      schema_config[:schema_includes].each do |mod|
        kls.schema_include(mod)
      end

      kls.class_eval(&block)

      class_name = classify_name(base_class_name, name.to_s)
      schema_class.const_set(class_name, kls)
      return kls, class_name
    end

    def create_schema(base_schema, schema_class, schema_name, data)
      if data.is_a?(Hash)
        schema = schema_class.from_hash(data)
        base_schema.parsing_errors.add(schema_name, :invalid) unless schema.parsing_errors.empty?
        schema
      elsif ! data.nil?
        base_schema.parsing_errors.add(schema_name, :incompatable)
        nil
      else
        nil
      end
    end
  end
end
