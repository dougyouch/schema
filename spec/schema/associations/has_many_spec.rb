require 'spec_helper'

describe Schema::Associations::HasMany do
  let(:model_class_name) { 'ModelClass' + SecureRandom.hex(10) }
  let(:model_class) do
    kls = Class.new do
      include Schema::Model
      schema_include Schema::Associations::HasMany
      attribute :name, :string

      has_many :items do
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
      items: [
        {
          id: rand(1_000_000),
          name: SecureRandom.hex(10),
          cost: (rand(1_000).to_f + rand).round(2)
        },
        {
          id: rand(1_000_000),
          name: SecureRandom.hex(10),
          cost: (rand(1_000).to_f + rand).round(2)
        }
      ]
    }
  end
  let(:model) { model_class.from_hash(model_data) }
  let(:parsing_errors) { model.parsing_errors }
  let(:has_parsing_errors) { ! parsing_errors.empty? }

  context 'has_many' do
    it 'sets the associated object' do
      expect(model.items.size).to eq(2)
      expect(model.items.first.id).to eq(model_data[:items].first[:id])
      expect(model.items.last.id).to eq(model_data[:items].last[:id])
      expect(has_parsing_errors).to eq(false)
    end

    describe 'incorrect model data' do
      let(:model_data) { {items: 'not valid'} }

      it 'association is nil' do
        expect(model.items).to eq(nil)
        expect(has_parsing_errors).to eq(true)
      end
    end

    describe 'nil model data' do
      let(:model_data) { {items: nil} }

      it 'association is nil' do
        expect(model.items).to eq(nil)
        expect(has_parsing_errors).to eq(false)
      end
    end

    describe 'parsing errors propogate' do
      let(:model_data) do
        {
          name: SecureRandom.uuid,
          items:
            [
              {
                id: 'not a number',
                name: SecureRandom.hex(10),
                cost: (rand(1_000).to_f + rand).round(2)
              }
            ]
        }
      end

      it 'has errors' do
        expect(model.items.first.id).to eq(nil)
        expect(model.items.first.name).to eq(model_data[:items].first[:name])
        expect(has_parsing_errors).to eq(true)
      end
    end
  end
end
