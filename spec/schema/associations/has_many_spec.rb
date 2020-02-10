require 'spec_helper'

describe Schema::Associations::HasMany do
  let(:model_class_name) { 'ModelClass' + SecureRandom.hex(10) }
  let(:model_class) do
    kls = Class.new do
      include Schema::Model
      schema_include Schema::Associations::HasMany
      attribute :name, :string

      has_many :items, aliases: [:my_items] do
        attribute :id, :integer
        attribute :name, :string
        attribute :cost, :float
      end

      has_many :users, default: true do
        attribute :id, :integer
        attribute :name, :string
      end

      has_many :buildings, as: :hash do
        attribute :name, :string
        attribute :code, :string
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

    describe 'aliases' do
      let(:model_data) do
        {
          name: SecureRandom.uuid,
          my_items: [
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

      it 'sets the associated object' do
        expect(model.items.size).to eq(2)
        expect(model.items.first.id).to eq(model_data[:my_items].first[:id])
        expect(model.items.last.id).to eq(model_data[:my_items].last[:id])
        expect(has_parsing_errors).to eq(false)
      end
    end

    describe 'default' do
      let(:model_data) { {} }

      it 'no default the association is nil' do
        expect(model.items.nil?).to eq(true)
      end

      it 'with default an empty association is created' do
        expect(model.users.nil?).to eq(false)
      end
    end

    describe 'as hash' do
      let(:model_data) do
        {
          buildings: {
            '1c' => {
              name: 'Building 1C',
              code: '51'
            },
            '33' => {
              name: 'Store Front',
              code: '021'
            }
          }
        }
      end

      subject { model.buildings }

      it { expect(subject.size).to eq(2) }
      it { expect(subject.is_a?(Hash)).to eq(false) }
      it { expect(subject.map(&:name)).to eq(['Building 1C', 'Store Front']) }
      it { expect(subject.map(&:code)).to eq(['51', '021']) }

      context 'building_as_hash' do
        subject { model.buildings_as_hash }

        it { expect(subject.size).to eq(2) }
        it { expect(subject.is_a?(Hash)).to eq(true) }
        it { expect(subject.keys).to eq(['1c', '33']) }
      end
    end
  end
end
