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
        if options.has_key?(:alias)
          options[:aliases] = [options[:alias]]
        end

        options = {
          key: name.to_s.freeze,
          name: name,
          type: type,
          getter: name.to_s.freeze,
          setter: "#{name}=".freeze,
          instance_variable: "@#{name}".freeze,
          parser: "parse_#{type}".freeze
        }.merge(options)

        add_value_to_class_method(:schema, name => options)

        class_eval(<<-STR
def #{options[:getter]}
  #{options[:instance_variable]}
end

def #{options[:setter]}(v)
  #{options[:instance_variable]} = #{options[:parser]}(#{name.inspect}, errors, v)
end
STR
        )

        if options[:aliases]
          options[:aliases].each do |alias_name|
            add_value_to_class_method(:schema, alias_name.to_sym => options.merge(key: alias_name.to_s, alias_of: name))
            alias_method(alias_name, options[:getter])
            alias_method("#{alias_name}=", options[:setter])
          end
        end
      end

      def from_hash(data)
        new.update_attributes(data)
      end
    end

    def update_attributes(data)
      self.class.schema.each do |field_name, field_options|
        next if ! data.has_key?(field_options[:key]) && ! data.has_key?(field_name)

        public_send(
          field_options[:setter],
          data[field_options[:key]] || data[field_name.to_sym]
        )
      end

      self
    end

    def as_json(opts={})
      self.class.schema.inject({}) do |memo, (field_name, field_options)|
        unless field_options[:alias_of]
          value = public_send(field_options[:getter])
          memo[field_name] = value if ! value.nil? || opts[:include_nils]
        end
        memo
      end
    end

    def to_hash
      as_json(include_nils: true)
    end
    alias to_h to_hash
  end
end
