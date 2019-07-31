require 'spec_helper'

describe Schema::Associations::SchemaCreator do
  let(:model_class_name) { 'ModelClass' + SecureRandom.hex(10) }
  let(:model_class) do
    kls = Class.new do
      include Schema::Model
      schema_include Schema::Associations::HasOne
      attribute :name, :string
      attribute :item_type, :string

      has_one :item do
        attribute :id, :integer
        attribute :type, :string
        attribute :name, :string
      end
    end
    Object.const_set(model_class_name, kls)
    Object.const_get(model_class_name)
  end
  let(:item_type_external) { nil }
  let(:item_data) do
    {
      id: rand(1_000_000),
      type: 'bar',
      name: SecureRandom.hex(10)
    }
  end
  let(:model_data) do
    {
      name: SecureRandom.uuid,
      item_type: item_type_external
    }
  end
  let(:model) { model_class.from_hash(model_data) }
  let(:schema_creator) { Schema::Associations::SchemaCreator.new(model, :item) }
  let(:item_model) { schema_creator.create_schema(model, item_data) }

  context 'create_schema' do
    subject { item_model }

    it 'creates the item' do
      expect(subject.type).to eq('bar')
    end
  end
end
