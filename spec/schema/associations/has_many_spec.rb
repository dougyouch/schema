# frozen_string_literal: true

require 'spec_helper'

describe Schema::Associations::HasMany do
  let(:model_class_name) { "ModelClass#{SecureRandom.hex(10)}" }
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

      has_many :tags

      has_many :buildings, from: :hash, hash_key_field: :id2 do
        attribute :id2, :string
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
  let(:skip_fields) { [] }
  let(:model) { model_class.from_hash(model_data, skip_fields) }
  let(:parsing_errors) { model.parsing_errors }
  let(:has_parsing_errors) { !parsing_errors.empty? }

  context 'has_many' do
    it 'sets the associated object' do
      expect(model.items.size).to eq(2)
      expect(model.items.first.id).to eq(model_data[:items].first[:id])
      expect(model.items.last.id).to eq(model_data[:items].last[:id])
      expect(has_parsing_errors).to eq(false)
    end

    describe 'incorrect model data' do
      let(:model_data) { { items: 'not valid' } }

      it 'association is nil' do
        expect(model.items).to eq(nil)
        expect(has_parsing_errors).to eq(true)
      end
    end

    describe 'nil model data' do
      let(:model_data) { { items: nil } }

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

      it 'reading the default does not count as set' do
        model.as_json
        expect(model.set_attribute_values).to eq({})
      end

      it 'keeps entries added to the default' do
        model.users << model_class.const_get(model_class.schema[:users][:class_name]).from_hash(id: 1)
        expect(model.as_json).to eq(users: [{ id: 1 }])
      end

      it 'deep_dup copies the default without sharing it' do
        model.users
        copy = model.deep_dup
        copy.users << nil
        expect(model.users).to eq([])
      end
    end

    describe 'from hash' do
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
      it { expect(subject.map(&:name)).to eq(['Building 1C', 'Store Front']) }
      it { expect(subject.map(&:code)).to eq(%w[51 021]) }

      describe 'with a value that is not a hash' do
        let(:model_data) { { buildings: { '1c' => 'not a hash', '33' => { name: 'Store Front' } } } }

        it 'leaves that entry nil and records an error' do
          expect(subject.first).to eq(nil)
          expect(subject.last.id2).to eq('33')
          expect(parsing_errors['buildings:1c']).to eq([Schema::ParsingErrors::INCOMPATIBLE])
        end
      end
    end

    describe 'as_json with a nil entry' do
      let(:model_data) { { items: [nil, { name: 'Widget' }] } }

      it 'serializes the nil entry as nil' do
        expect(model.as_json).to eq(items: [nil, { name: 'Widget' }], users: [])
      end
    end

    describe 'without a block' do
      let(:model_data) { { tags: [{}, {}] } }

      it 'creates an empty schema for each element' do
        expect(model.tags.size).to eq(2)
        expect(has_parsing_errors).to eq(false)
      end
    end

    describe 'append_to' do
      let(:model_data) { {} }

      before do
        model.append_to_users(id: 1, name: 'Foo Bar')
      end

      it 'appended the user' do
        expect(model.as_json).to eq({ users: [{ id: 1, name: 'Foo Bar' }] })
      end
    end

    describe 'skip_fields' do
      let(:skip_fields) { [{ items: [:id] }] }

      it 'sets item id to nil' do
        expect(model.items.map(&:id)).to eq([nil, nil])
      end

      describe 'with string keys' do
        let(:model_data) { { 'items' => [{ 'id' => 1, 'name' => 'Widget' }] } }

        it 'sets item id to nil' do
          expect(model.items.map(&:id)).to eq([nil])
          expect(model.items.map(&:name)).to eq(['Widget'])
        end
      end

      describe 'set through the association alias' do
        let(:model_data) { { my_items: [{ id: 1, name: 'Widget' }] } }

        it 'sets item id to nil' do
          expect(model.items.map(&:id)).to eq([nil])
        end
      end

      describe 'mixed with other skip_fields' do
        let(:skip_fields) { [:name, { users: [:id] }, { items: [:id] }] }

        it 'applies the matching nested list' do
          expect(model.name).to eq(nil)
          expect(model.items.map(&:id)).to eq([nil, nil])
        end
      end

      describe 'skipping the whole association' do
        let(:skip_fields) { [:items] }

        it 'leaves items unset' do
          expect(model.items).to eq(nil)
        end
      end
    end
  end
end
