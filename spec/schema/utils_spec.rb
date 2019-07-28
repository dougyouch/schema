require 'spec_helper'

describe Schema::Utils do
  context 'classify_name' do
    let(:name) { 'name-foo_bar_1!' }

    subject { Schema::Utils.classify_name(name) }

    it 'converts the name to a class name' do
      expect(subject).to eq('NameFooBar1')
    end
  end

  context 'create_schema' do
    let(:base_class_name) { 'BaseClass' + SecureRandom.hex(10) }
    let(:base_class) do
      kls = Class.new do
        include Schema::Model
      end
      Object.const_set(base_class_name, kls)
      Object.const_get(base_class_name)
    end
    let(:base_model) { base_class.new }
    let(:base_model_has_errors) { ! base_model.parsing_errors.empty? }

    let(:schema_class_name) { 'SchemaClass' + SecureRandom.hex(10) }
    let(:schema_class) do
      kls = Class.new do
        include Schema::Model

        attribute :name, :string
        attribute :type, :integer
      end
      Object.const_set(schema_class_name, kls)
      Object.const_get(schema_class_name)
    end
    let(:schema_name) { :user }
    let(:schema_data) do
      {
        name: 'Foo Bar',
        type: 5
      }
    end

    subject { Schema::Utils.create_schema(base_model, schema_class, schema_name, schema_data) }

    it 'creates the schema without errors' do
      expect(subject.nil?).to eq(false)
      expect(subject.parsing_errors.empty?).to eq(true)
      expect(base_model_has_errors).to eq(false)
    end

    describe 'nil schema data' do
      let(:schema_data) { nil }

      it 'no schema is created, and no errors' do
        expect(subject).to eq(nil)
        expect(base_model_has_errors).to eq(false)
      end
    end

    describe 'invalid schema data' do
      let(:schema_data) { 'not valid schema data' }

      it 'no schema is created, and has errors' do
        expect(subject).to eq(nil)
        expect(base_model_has_errors).to eq(true)
      end
    end
  end
end
