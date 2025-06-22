require 'spec_helper'

describe Schema::Assign do
  let(:schema_class_name) { 'SchemaClass' + SecureRandom.hex(10) }
  let(:schema_class) do
    kls = Class.new do
      include Schema::All

      attribute :id, :integer
      attribute :name, :string
      attribute :cost, :float, default: 0.0
    end
    Object.const_set(schema_class_name, kls)
    Object.const_get(schema_class_name)
  end
  let(:id) { rand(1_000_000) }
  let(:name) { SecureRandom.hex(10) }
  let(:cost) { (rand(1_000).to_f + rand).round(2) }
  let(:schema_data) do
    {
      id: id,
      name: name,
      cost: cost
    }
  end
  let(:schema) { schema_class.from_hash(schema_data) }
  let(:model_class) do
    Struct.new(:id, :name, :cost, :user_id)
  end
  let(:model) { model_class.new }
  let(:include_filter) { nil }
  let(:exclude_filter) { nil }

  context '.update_model' do
    subject do
      Schema::Assign.update_model(
        schema: schema,
        model: model,
        include_filter: include_filter,
        exclude_filter: exclude_filter
      )
    end

    before(:each) do
      subject
    end

    it { expect(model.id).to eq(id) }
    it { expect(model.name).to eq(name) }
    it { expect(model.cost).to eq(cost) }
    it { expect(model.user_id).to eq(nil) }
  end
end
