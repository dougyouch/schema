require 'spec_helper'

describe Schema::Model do
  let(:model_class_name) { 'ModelClass' + SecureRandom.hex(10) }
  let(:model_class) do
    kls = Class.new do
      include Schema::Model
      schema_include ActiveModel::Validations

      attribute :id, :integer, alias: :identifier
      attribute :name, :string, aliases: [:my_name]
      attribute :cost, :float
    end
    Object.const_set(model_class_name, kls)
    Object.const_get(model_class_name)
  end
  let(:model_data) do
    {
      id: rand(1_000_000),
      name: SecureRandom.hex(10),
      cost: (rand(1_000).to_f + rand).round(2)
    }
  end
  let(:model) { model_class.from_hash(model_data) }

  context 'attribute' do
    describe 'adds setter/getter methods to the class' do
      let(:attribute_name) { :other }
      subject { model_class.attribute attribute_name, :integer }

      it 'adds the attriburte to the schema' do
        subject
        expect(model_class.schema.has_key?(attribute_name)).to eq(true)
      end
    end
  end

  context 'setter/getter' do
    let(:value) { rand(1_000_000).to_s }
    let(:model) { model_class.new }

    it 'get/set model attribute' do
      model.id = value
      expect(model.instance_variable_get(:@id)).to eq(value.to_i)
      expect(model.id).to eq(value.to_i)
      expect(model.instance_variable_get(:@id).object_id).to eq(model.id.object_id)
    end
  end

  context 'from_hash' do
    let(:value) { rand(1_000_000).to_s }

    subject { model_class.from_hash id: value }

    it 'transformed and assigned the value' do
      expect(subject.id).to eq(value.to_i)
    end

    describe 'string keys' do
      subject { model_class.from_hash 'identifier' => value }

      it 'transformed and assigned the value' do
        expect(subject.id).to eq(value.to_i)
      end
    end
  end

  context 'as_json' do
    let(:include_nils) { false }
    subject { model.as_json(include_nils: include_nils) }

    it 'returns a hash' do
      expect(subject).to eq(model_data)
    end

    describe 'nil values' do
      let(:model_data) do
        {
          id: rand(1_000_000),
          name: nil,
          cost: (rand(1_000).to_f + rand).round(2)
        }
      end

      it 'omits nil values' do
        expect(subject).to eq(id: model_data[:id],
                              cost: model_data[:cost])
      end

      describe 'include nils values' do
        let(:include_nils) { true }

        it 'returns a hash with nil values' do
          expect(subject).to eq(model_data)
        end
      end
    end
  end

  context 'to_hash' do
    subject { model.to_hash }

    it 'returns a hash' do
      expect(subject).to eq(model_data)
    end

    describe 'nil values' do
      let(:model_data) do
        {
          id: rand(1_000_000),
          name: nil,
          cost: (rand(1_000).to_f + rand).round(2)
        }
      end

      it 'returns a hash with nil values' do
        expect(subject).to eq(model_data)
      end
    end
  end
end
