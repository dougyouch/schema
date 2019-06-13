require 'spec_helper'

describe Schema::Model do
  let(:model_class_name) { 'ModelClass' + SecureRandom.hex(10) }
  let(:model_class) do
    kls = Class.new do
      include ActiveModel::Validations
      include Schema::Model
    end
    Object.const_set(model_class_name, kls)
    Object.const_get(model_class_name)
  end
  let(:model_data) do
    {
      'id' => rand(1_000_000),
      'name' => SecureRandom.hex(10),
      'cost' => (rand(1_000).to_f + rand).round(2)
    }
  end
  let(:model) { model_class.from_hash(model_data) }

  context 'attribute' do
    describe 'adds setter/getter methods to the class' do
      let(:attribute_name) { :id }
      subject { model_class.attribute attribute_name, :integer }

      it 'adds the attriburte to the schema' do
        subject
        expect(model_class.schema.has_key?(attribute_name)).to eq(true)
      end
    end
  end
end
