require 'spec_helper'

describe 'dynamic has many' do
  let(:model_class_name) { 'ModelClass' + SecureRandom.hex(10) }
  let(:model_class) do
    kls = Class.new
    kls = Object.const_set(model_class_name, kls)
    kls.class_eval do
      include Schema::Model
      schema_include Schema::Associations::HasMany
      attribute :name, :string

      has_many :items, type_field: :type do
        attribute :id, :integer
        attribute :name, :string
        attribute :type, :string

        add_type('foo') do
          attribute :foo, :string
        end

        add_type('bar') do
          attribute :bar, :string
        end
      end
    end
    Object.const_get(model_class_name)
  end


  describe 'valid types' do
    let(:foo_value) { 'value of foo ' + SecureRandom.hex(8) }
    let(:bar_value) { 'value of bar ' + SecureRandom.hex(8) }
    let(:payload) do
      {
        name: 'Name ' + SecureRandom.hex(8),
        items: [
          {
            id: rand(1_000_000),
            name: 'ItemName ' + SecureRandom.hex(8),
            type: 'bar',
            bar: bar_value
          },
          {
            id: rand(1_000_000),
            name: 'ItemName ' + SecureRandom.hex(8),
            type: 'foo',
            foo: foo_value
          }
        ]
      }
    end

    subject { model_class.from_hash(payload) }

    it 'creates the dynamic associations' do
      expect(subject.items[0].bar).to eq(bar_value)
      expect(subject.items[1].foo).to eq(foo_value)
    end
  end

  describe 'invalid type' do
    let(:foo_value) { 'value of foo ' + SecureRandom.hex(8) }
    let(:bar_value) { 'value of bar ' + SecureRandom.hex(8) }
    let(:payload) do
      {
        name: 'Name ' + SecureRandom.hex(8),
        items: [
          {
            id: rand(1_000_000),
            name: 'ItemName ' + SecureRandom.hex(8),
            type: 'bar',
            bar: bar_value
          },
          {
            id: rand(1_000_000),
            name: 'ItemName ' + SecureRandom.hex(8),
            type: 'invalid',
            bar: 'bar not set',
            foo: 'foo not set'
          },
          {
            id: rand(1_000_000),
            name: 'ItemName ' + SecureRandom.hex(8),
            type: 'foo',
            foo: foo_value
          }
        ]
      }
    end

    subject { model_class.from_hash(payload) }

    it 'unknown types do not create associations' do
      expect(subject.items[0].bar).to eq(bar_value)
      expect(subject.items[1]).to eq(nil)
      expect(subject.items[2].foo).to eq(foo_value)
    end

    it 'parsing_errors unknown item with index' do
      expect(subject.parsing_errors['items:1']).to eq([:unknown])
    end
  end
end
