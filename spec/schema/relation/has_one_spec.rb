require 'spec_helper'

describe Schema::Relation::HasOne do
  let(:model_class_name) { 'ModelClass' + SecureRandom.hex(10) }
  let(:model_class) do
    kls = Class.new do
      include Schema::Model
      schema_include Schema::Relation::HasOne
      schema_include ActiveModel::Validations
      attribute :name, :string

      has_one :item do
        attribute :id, :integer
        attribute :name, :string
        attribute :cost, :float
      end
    end
    Object.const_set(model_class_name, kls)
    Object.const_get(model_class_name)
  end
  let(:model_data) do
    {
      name: SecureRandom.uuid,
      item: {
        id: rand(1_000_000),
        name: SecureRandom.hex(10),
        cost: (rand(1_000).to_f + rand).round(2)
      }
    }
  end
  let(:model) { model_class.from_hash(model_data) }

  context 'has_one' do
    it 'sets the relation object' do
      expect(model.item.id).to eq(model_data[:item][:id])
    end
  end
end
