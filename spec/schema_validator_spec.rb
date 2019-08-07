require 'spec_helper'
require 'active_model'

describe SchemaValidator do
  let(:model_class_name) { 'ModelClass' + SecureRandom.hex(10) }
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
        name: 'Name ' + SecureRandom.hex(8),
        item: {
          id: rand(1_000_000),
          name: 'ItemName ' + SecureRandom.hex(8),
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

  describe 'invalid payload' do
    let(:payload) do
      {
        name: 'Name ' + SecureRandom.hex(8),
        item: {
          id: rand(1_000_000),
          name: 'ItemName ' + SecureRandom.hex(8)
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
