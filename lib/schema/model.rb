require 'inheritance-helper'

module Schema
  module Model
    def self.included base
      base.extend InheritanceHelper::Methods
      base.include Schema::Parsers::Common
      base.extend ClassMethods
    end

    module ClassMethods
      def schema
        {}.freeze
      end

      def attribute(name, type, options={})
        options = {
          type: type,
          getter: name.to_s,
          setter: "#{name}=",
          instance_variable: "@#{name}",
          parser: "parse_#{type}"
        }.merge(options)

        add_value_to_class_method(:schema, name => options)

        class_eval(<<-STR
def #{options[:getter]}
  #{options[:instance_variable]}
end

def #{options[:setter]}(v)
  #{options[:instance_variable]} = #{options[:parser]}('#{name}', errors, v)
end
STR
        )
      end

      def from_hash(data)
        new.update_attributes(data)
      end
    end

    def update_attributes(data)
      self.class.schema.each do |field_name, field_options|
        next unless data.has_key?(field_name)
        public_send(field_options[:setter], value)
      end
      self
    end
  end
end
