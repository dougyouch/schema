# frozen_string_literal: true

require 'spec_helper'

describe Schema::ActiveModelValidations do
  let(:model_class_name) { "ModelClass#{SecureRandom.hex(10)}" }
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

  context '#parsed_and_valid?' do
    it 'is true when there are no parsing or validation errors' do
      expect(model.parsed_and_valid?).to eq(true)
    end

    describe 'parsing error' do
      let(:model_data) { { id: 'not_a_number' } }

      it 'is false and still runs the validations' do
        expect(model.parsed_and_valid?).to eq(false)
        expect(model.errors[:id]).to eq(["can't be blank"])
      end
    end

    describe 'validation error' do
      let(:id) { nil }

      it 'is false' do
        expect(model.parsed_and_valid?).to eq(false)
      end
    end
  end

  context '#full_error_messages' do
    let(:model_data) { { id: 'not_a_number', other: 1 } }

    it 'lists parsing messages then validation messages' do
      model.parsed_and_valid?
      expect(model.full_error_messages).to eq(['Id is invalid', 'Other is an unknown attribute', "Id can't be blank"])
    end
  end

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
