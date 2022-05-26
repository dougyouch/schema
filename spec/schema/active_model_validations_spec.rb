require 'spec_helper'

describe Schema::ActiveModelValidations do
  let(:model_class_name) { 'ModelClass' + SecureRandom.hex(10) }
  let(:model_class) do
    kls = Class.new do
      include Schema::Model
      include Schema::ActiveModelValidations

      attribute :id, :integer

      validates :id, presence: true
    end
    Object.const_set(model_class_name, kls)
    Object.const_get(model_class_name)
  end
  let(:id) { rand(1_000_000) }
  let(:model_data) do
    {
      id: id
    }
  end
  let(:model) { model_class.from_hash(model_data) }

  context '#valid!' do
    subject { model.valid! }

    it { expect { subject }.not_to raise_error }

    describe 'parsing error' do
      let(:id) { 'not_a_number' }

      it { expect { subject }.to raise_error(Schema::ParsingException) }
    end

    describe 'model error' do
      let(:id) { nil }

      it { expect { subject }.to raise_error(Schema::ValidationException) }
    end
  end
end
