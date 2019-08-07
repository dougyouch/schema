require 'spec_helper'

describe Schema::Associations::DynamicTypes do
  let(:model_class_name) { 'ModelClass' + SecureRandom.hex(10) }
  let(:model_class) do
    kls = Class.new
    kls = Object.const_set(model_class_name, kls)
    kls.class_eval do
      include Schema::Model
      schema_include Schema::Associations::HasOne
      attribute :name, :string
      attribute :type, :string

      has_one :item, type_field: :type do
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

  let(:item_class) { model_class.const_get(model_class.schema[:item][:class_name]) }

  context '.dynamic_type_names' do
    it 'item has 2 types' do
      expect(item_class.dynamic_type_names).to eq(['foo', 'bar'])
    end
  end

  context '#add_type' do
    it 'item has 2 types' do
      expect(model_class.schema[:item][:types].keys).to eq(['foo', 'bar'])
    end

    describe 'valid type' do
      let(:foo_value) { 'value of foo ' + SecureRandom.hex(8) }
      let(:payload) do
        {
          name: 'Name ' + SecureRandom.hex(8),
          item: {
            id: rand(1_000_000),
            name: 'ItemName ' + SecureRandom.hex(8),
            type: 'foo',
            foo: foo_value
          }
        }
      end

      subject { model_class.from_hash(payload) }

      it 'creates the dynamic association' do
        expect(subject.item.foo).to eq(foo_value)
      end
    end

    describe 'invalid type' do
      let(:foo_value) { 'value of foo ' + SecureRandom.hex(8) }
      let(:payload) do
        {
          name: 'Name ' + SecureRandom.hex(8),
          item: {
            id: rand(1_000_000),
            name: 'ItemName ' + SecureRandom.hex(8),
            type: 'foo2',
            foo: foo_value
          }
        }
      end

      subject { model_class.from_hash(payload) }

      it 'association is nil when the type is invalid' do
        expect(subject.item).to eq(nil)
      end

      it 'parsing_errors unknown item' do
        expect(subject.parsing_errors[:item]).to eq([:unknown])
      end
    end

    describe 'valid type unknown fields' do
      let(:foo_value) { 'value of foo ' + SecureRandom.hex(8) }
      let(:payload) do
        {
          name: 'Name ' + SecureRandom.hex(8),
          item: {
            id: rand(1_000_000),
            name: 'ItemName ' + SecureRandom.hex(8),
            type: 'bar',
            foo: foo_value
          }
        }
      end

      subject { model_class.from_hash(payload) }

      it 'creates the dynamic association' do
        expect(subject.item.bar).to eq(nil)
      end

      it 'parsing_errors unknown_attribute' do
        expect(subject.parsing_errors[:item]).to eq([:invalid])
        expect(subject.item.parsing_errors[:foo]).to eq(['unknown_attribute'])
      end
    end

    describe 'valid type upcased' do
      let(:foo_value) { 'value of foo ' + SecureRandom.hex(8) }
      let(:payload) do
        {
          name: 'Name ' + SecureRandom.hex(8),
          item: {
            id: rand(1_000_000),
            name: 'ItemName ' + SecureRandom.hex(8),
            type: 'FOO',
            foo: foo_value
          }
        }
      end

      subject { model_class.from_hash(payload) }

      it 'association is nil when the type is invalid' do
        expect(subject.item).to eq(nil)
      end

      it 'parsing_errors unknown item' do
        expect(subject.parsing_errors[:item]).to eq([:unknown])
      end

      describe 'with type_ignorecase flag' do
        before(:each) do
          schema_options = model_class.schema[:item].dup
          schema_options[:type_ignorecase] = true
          model_class.add_value_to_class_method(:schema, item: schema_options)
        end

        it 'creates the dynamic association' do
          expect(subject.item.foo).to eq(foo_value)
        end
      end
    end
  end

  context 'external_type_field option' do
    before(:each) do
      schema_options = model_class.schema[:item].dup
      schema_options.delete(:type_field)
      schema_options[:external_type_field] = :type
      model_class.add_value_to_class_method(:schema, item: schema_options)
    end

    describe 'valid type' do
      let(:foo_value) { 'value of foo ' + SecureRandom.hex(8) }
      let(:payload) do
        {
          name: 'Name ' + SecureRandom.hex(8),
          type: 'foo',
          item: {
            id: rand(1_000_000),
            name: 'ItemName ' + SecureRandom.hex(8),
            foo: foo_value
          }
        }
      end

      subject { model_class.from_hash(payload) }

      it 'creates the dynamic association' do
        expect(subject.item.foo).to eq(foo_value)
      end
    end

    describe 'invalid type' do
      let(:foo_value) { 'value of foo ' + SecureRandom.hex(8) }
      let(:payload) do
        {
          name: 'Name ' + SecureRandom.hex(8),
          type: 'invalid',
          item: {
            id: rand(1_000_000),
            name: 'ItemName ' + SecureRandom.hex(8),
            foo: foo_value
          }
        }
      end

      subject { model_class.from_hash(payload) }

      it 'association is nil when the type is invalid' do
        expect(subject.item).to eq(nil)
      end

      it 'parsing_errors unknown item' do
        expect(subject.parsing_errors[:item]).to eq([:unknown])
      end
    end
  end
end
