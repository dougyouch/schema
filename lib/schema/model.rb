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
        add_value_to_class_method(:schema,
                                  name => {
                                    type: type,
                                    getter_method: name.to_s,
                                    setter_method: "#{name}="
                                  }.merge(options)
                                 )

        class_eval(<<-STR
def #{name}
  @#{name}
end

def #{name}=(v)
  @#{name} = parse_#{type}('#{name}', errors, v)
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
        next unless value = data[field_name]
        public_send(field_options[:setter_method], value)
      end
      self
    end
  end
end
