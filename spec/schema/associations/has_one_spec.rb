require 'spec_helper'

describe Schema::Associations::HasOne do
  let(:model_class_name) { 'ModelClass' + SecureRandom.hex(10) }
  let(:model_class) do
    kls = Class.new do
      include Schema::Model
      schema_include Schema::Associations::HasOne
      attribute :name, :string

      has_one :item, alias: :my_item do
        attribute :id, :integer
        attribute :name, :string
        attribute :cost, :float
      end

      has_one :user, default: true do
        attribute :id, :integer
        attribute :name, :string
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
  let(:skip_fields) { [] }
  let(:model) { model_class.from_hash(model_data, skip_fields) }
  let(:parsing_errors) { model.parsing_errors }
  let(:has_parsing_errors) { ! parsing_errors.empty? }

  context 'has_one' do
    it 'sets the associated object' do
      expect(model.item.id).to eq(model_data[:item][:id])
      expect(has_parsing_errors).to eq(false)
    end

    describe 'incorrect model data' do
      let(:model_data) { {item: 'not valid'} }

      it 'association is nil' do
        expect(model.item).to eq(nil)
        expect(has_parsing_errors).to eq(true)
      end
    end

    describe 'nil model data' do
      let(:model_data) { {item: nil} }

      it 'association is nil' do
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

    describe 'aliases' do
      let(:model_data) do
        {
          name: SecureRandom.uuid,
          my_item: {
            id: rand(1_000_000),
            name: SecureRandom.hex(10),
            cost: (rand(1_000).to_f + rand).round(2)
          }
        }
      end

      it 'sets the associated object' do
        expect(model.item.id).to eq(model_data[:my_item][:id])
        expect(has_parsing_errors).to eq(false)
      end
    end

    describe 'default' do
      let(:model_data) { {} }

      it 'no default the association is nil' do
        expect(model.item.nil?).to eq(true)
      end

      it 'with default an empty association is created' do
        expect(model.user.nil?).to eq(false)
      end
    end

    describe 'skip_fields' do
      let(:skip_fields) { [item: [:id]] }

      it 'set item id to nil' do
        expect(model.item.id).to eq(nil)
      end
    end
  end
end
