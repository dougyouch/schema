require 'spec_helper'

describe Schema::Relation::HasOne do
  let(:model_class_name) { 'ModelClass' + SecureRandom.hex(10) }
  let(:model_class) do
    kls = Class.new do
      include Schema::Model
      schema_include Schema::Relation::HasOne
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
  let(:parsing_errors) { model.parsing_errors }
  let(:has_parsing_errors) { ! parsing_errors.empty? }

  context 'has_one' do
    it 'sets the relation object' do
      expect(model.item.id).to eq(model_data[:item][:id])
      expect(has_parsing_errors).to eq(false)
    end

    describe 'incorrect model data' do
      let(:model_data) { {item: 'not valid'} }

      it 'relationship is nil' do
        expect(model.item).to eq(nil)
        expect(has_parsing_errors).to eq(true)
      end
    end

    describe 'nil model data' do
      let(:model_data) { {item: nil} }

      it 'relationship is nil' do
        expect(model.item).to eq(nil)
        expect(has_parsing_errors).to eq(false)
      end
    end

    describe 'parsing errors propogate' do
      let(:model_data) do
        {
          name: SecureRandom.uuid,
          item: {
            id: 'not a number',
            name: SecureRandom.hex(10),
            cost: (rand(1_000).to_f + rand).round(2)
          }
        }
      end

      it 'has errors' do
        expect(model.item.id).to eq(nil)
        expect(model.item.name).to eq(model_data[:item][:name])
        expect(has_parsing_errors).to eq(true)
      end
    end
  end
end
