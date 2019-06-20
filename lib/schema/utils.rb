module Schema
  module Utils
    extend self

    def classify_name(base, name)
      base + name.gsub(/[^\da-z_-]/, '').gsub(/(^.|[_|-].)/) { |m| m[-1].upcase }
    end

    def create_schema(base_schema, schema_class, schema_name, data)
      if data.is_a?(Hash)
        schema = schema_class.from_hash(data)
        base_schema.errors.add(schema_name, :invalid) unless schema.errors.empty?
        schema
      elsif ! data.nil?
        base_schema.errors.add(schema_name, :incompatable)
        nil
      else
        nil
      end
    end
  end
end
