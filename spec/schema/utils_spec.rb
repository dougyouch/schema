require 'spec_helper'

describe Schema::Utils do
  context 'classify_name' do
    let(:name) { 'name-foo_bar_1!' }

    subject { Schema::Utils.classify_name(name) }

    it 'converts the name to a class name' do
      expect(subject).to eq('NameFooBar1')
    end
  end

  context '.get_dynamic_type' do
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
    let(:schema_data) do
      {
        name: 'Foo Bar',
        type: 5
      }
    end
    let(:data) do
      {
        type: 'manager',
        count: 5
      }
    end
    let(:type_field) { :type }
    let(:external_type_field) { nil }
    let(:aliases) { nil }
    let(:base_schema) { schema_class.from_hash(schema_data) }

    subject { Schema::Utils.get_dynamic_type(base_schema, data, type_field, external_type_field, aliases) }

    it 'returns the type' do
      expect(subject).to eq('manager')
    end

    describe 'data uses string fields' do
      let(:data) do
        {
          'type' => 'manager',
          'count' => 5
        }
      end

      it 'returns the type' do
        expect(subject).to eq('manager')
      end
    end

    describe 'missing type field' do
      let(:data) do
        {
          'type_invalid' => 'manager',
          'count' => 5
        }
      end

      it 'returns nil' do
        expect(subject).to eq(nil)
      end
    end

    describe 'aliases' do
      let(:aliases) { ['type1', 'type2'] }
      let(:data) do
        {
          'type2' => 'manager',
          'count' => 5
        }
      end

      it 'returns the type' do
        expect(subject).to eq('manager')
      end
    end

    describe 'with aliases but key not found' do
      let(:aliases) { ['type1', 'type2'] }
      let(:data) do
        {
          'type3' => 'manager',
          'count' => 5
        }
      end

      it 'returns the type' do
        expect(subject).to eq(nil)
      end
    end

    describe 'external_type_field' do
      let(:type_field) { nil }
      let(:external_type_field) { :type }

      it 'returns the type' do
        expect(subject).to eq(5)
      end
    end
  end

  context '.get_dynamic_schema_class' do
    let(:type) { 'manager' }
    let(:employee_class) { Class.new }
    let(:manager_class) { Class.new }
    let(:types) do
      {
        'employee' => employee_class,
        'manager' => manager_class
      }
    end
    let(:ignorecase) { false }
    subject { Schema::Utils.get_dynamic_schema_class(type, types, ignorecase) }

    it 'returns the class based on type' do
      expect(subject).to eq(manager_class)
    end

    describe 'ignorecase' do
      let(:ignorecase) { true }
      let(:type) { 'MANAGER' }

      it 'returns the class based on type' do
        expect(subject).to eq(manager_class)
      end
    end

    describe 'invalid type' do
      let(:type) { 'MANAGER' }

      it 'returns nil' do
        expect(subject).to eq(nil)
      end
    end
  end

  context '.create_dynamic_schema' do
    let(:has_one_type_field) { :type }
    let(:has_one_external_type_field) { nil }
    let(:has_one_aliases) { nil }
    let(:aliases) { nil }
    let(:schema_class_name) { 'SchemaClass' + SecureRandom.hex(10) }
    let(:employee_class) do
      aliases = has_one_aliases
      Class.new do
        include Schema::Model

        attribute :type, :string, aliases: aliases
        attribute :count, :integer
      end
    end   
    let(:manager_class) do
      aliases = has_one_aliases
      Class.new do
        include Schema::Model

        attribute :type, :string, aliases: aliases
        attribute :count, :integer
      end
    end
    let(:has_one_types) do
      {
        'employee' => employee_class,
        'manager' => manager_class
      }
    end
    let(:schema_class) do
      type_field = has_one_type_field
      external_type_field = has_one_external_type_field
      types = has_one_types
      aliases = has_one_aliases
      kls = Class.new do
        include Schema::Model
        include Schema::Associations::HasOne

        attribute :name, :string
        attribute :type, :integer

        has_one(:person, type_field: type_field, external_type_field: external_type_field, types: types)
      end
      Object.const_set(schema_class_name, kls)
      Object.const_get(schema_class_name)
    end
    let(:person_data) do
      {
        type: 'manager',
        count: 5
      }
    end
    let(:data) do
      {
        name: 'Foo Bar',
        type: 5,
        person: person_data
      }
    end
    let(:schema_name) { :person }
    let(:base_schema) { schema_class.from_hash(data) }
    let(:error_name) { nil }

    subject { Schema::Utils.create_dynamic_schema(base_schema, schema_name, data, error_name) }

    it 'creates a schema object using the correct class' do
      expect(subject.class).to eq(manager_class)
    end
  end
end
