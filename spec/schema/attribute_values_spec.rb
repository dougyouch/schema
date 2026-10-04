# frozen_string_literal: true

require 'spec_helper'

describe Schema::AttributeValues do
  let(:model_class_name) { "ModelClass#{SecureRandom.hex(10)}" }
  let(:model_class) do
    kls = Class.new do
      include Schema::Model

      schema_include Schema::Associations::HasMany

      attribute :name, :string, alias: :full_name
      attribute :age, :integer, default: 0

      has_many :phones do
        attribute :number, :string
      end
    end
    Object.const_set(model_class_name, kls)
  end
  let(:data) { { name: 'Joe', phones: [{ number: '555' }] } }
  let(:model) { model_class.from_hash(data) }

  context '#attribute_values' do
    it 'returns every attribute without aliases, defaults included' do
      expect(model.attribute_values.keys).to eq(%i[name age phones])
      expect(model.attribute_values[:age]).to eq(0)
    end
  end

  context '#==' do
    it 'is equal to a model with the same values' do
      expect(model).to eq(model_class.from_hash(full_name: 'Joe', age: '0', phones: [{ number: '555' }]))
    end

    it 'is not equal when a nested value differs' do
      expect(model).not_to eq(model_class.from_hash(name: 'Joe', phones: [{ number: '556' }]))
    end

    it 'is not equal to another class with the same values' do
      other_class = Class.new(model_class)
      expect(model).not_to eq(other_class.from_hash(data))
    end
  end

  context '#inspect' do
    it 'lists the attributes that were set' do
      expect(model.inspect).to eq(
        "#<#{model_class_name} name: \"Joe\", phones: [#<#{model_class_name}::SchemaHasManyPhones number: \"555\">]>"
      )
    end

    it 'shows just the class name when nothing was set' do
      expect(model_class.new.inspect).to eq("#<#{model_class_name}>")
    end
  end
end
