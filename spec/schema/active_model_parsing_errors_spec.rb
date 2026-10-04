# frozen_string_literal: true

require 'spec_helper'

describe Schema::ActiveModelParsingErrors do
  let(:model_class_name) { "ModelClass#{SecureRandom.hex(10)}" }
  let(:model_class) do
    kls = Class.new do
      include Schema::All

      attribute :age, :integer

      has_one :company do
        attribute :name, :string
      end
    end
    Object.const_set(model_class_name, kls)
  end

  it 'uses readable messages for parsing error codes' do
    model = model_class.from_hash(age: 'x', other: 1, company: 'Acme')
    expect(model.parsing_errors.full_messages).to eq(
      ['Age is invalid', 'Other is an unknown attribute', 'Company is an incompatible type']
    )
  end

  it 'keeps other messages as is' do
    model = model_class.new
    model.parsing_errors.add(:age, 'is too old')
    expect(model.parsing_errors[:age]).to eq(['is too old'])
  end

  it 'can be translated' do
    I18n.backend.store_translations(:en, schema: { parsing_errors: { invalid: 'is not valid' } })
    expect(model_class.from_hash(age: 'x').parsing_errors[:age]).to eq(['is not valid'])
  ensure
    I18n.backend.reload!
  end
end
