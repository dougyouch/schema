# frozen_string_literal: true

require 'spec_helper'
require 'active_model'

describe SchemaValidator do
  let(:model_class_name) { "ModelClass#{SecureRandom.hex(10)}" }
  let(:model_class) do
    kls = Class.new do
      include Schema::Model

      schema_include Schema::Associations::HasOne
      include Schema::ActiveModelValidations

      attribute :name, :string

      has_one :item do
        attribute :id, :integer
        attribute :name, :string
        attribute :cost, :float

        validates :id, presence: true
        validates :name, presence: true
        validates :cost, presence: true
      end

      validates :name, presence: true
      validates :item, presence: true, schema: true
    end
    Object.const_set(model_class_name, kls)
    Object.const_get(model_class_name)
  end

  describe 'valid payload no errors' do
    let(:payload) do
      {
        name: "Name #{SecureRandom.hex(8)}",
        item: {
          id: rand(1_000_000),
          name: "ItemName #{SecureRandom.hex(8)}",
          cost: 900.5
        }
      }
    end

    let(:model) { model_class.from_hash(payload) }

    subject { model.errors }

    before(:each) { model.valid? }

    it 'has no errors' do
      expect(subject.empty?).to eq(true)
    end

    it 'item has no errors' do
      expect(model.item.errors.empty?).to eq(true)
    end
  end

  describe 'nested schema with parsing errors' do
    let(:model) do
      model_class.from_hash(name: 'Name', item: { id: 1, name: 'Item', cost: 1.5, extra: 'unknown key' })
    end

    before(:each) { model.valid? }

    it 'is invalid even though the nested validations pass' do
      expect(model.item.valid?).to eq(true)
      expect(model.errors[:item]).to eq(['is invalid'])
    end
  end

  describe 'list of nested schemas' do
    let(:list_class) do
      kls = Class.new do
        include Schema::All

        has_many :items do
          attribute :name, :string
          validates :name, presence: true
        end

        validates :items, schema: true
      end
      Object.const_set("ModelClass#{SecureRandom.hex(10)}", kls)
    end
    let(:model) { list_class.from_hash(items: [{}, nil, {}]) }

    before(:each) { model.valid? }

    it 'validates every entry, skipping nil ones' do
      expect(model.errors[:items]).to eq(['is invalid'])
      expect(model.items.compact.map { |item| item.errors[:name] }).to eq([["can't be blank"], ["can't be blank"]])
    end
  end

  describe 'missing nested schema' do
    let(:model) { model_class.from_hash(name: "Name #{SecureRandom.hex(8)}") }

    subject { model.errors }

    before(:each) { model.valid? }

    it 'only reports the presence error' do
      expect(subject[:item]).to eq(["can't be blank"])
    end
  end

  describe 'invalid payload' do
    let(:payload) do
      {
        name: "Name #{SecureRandom.hex(8)}",
        item: {
          id: rand(1_000_000),
          name: "ItemName #{SecureRandom.hex(8)}"
        }
      }
    end

    let(:model) { model_class.from_hash(payload) }

    subject { model.errors }

    before(:each) { model.valid? }

    it 'has errors' do
      expect(subject.empty?).to eq(false)
    end

    it 'item has errors' do
      expect(model.item.errors.empty?).to eq(false)
    end

    it 'cost has an error' do
      expect(model.item.errors[:cost]).to eq(["can't be blank"])
    end
  end
end
