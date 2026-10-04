# frozen_string_literal: true

require 'spec_helper'

describe Schema::DeepCopy do
  let(:model_class) do
    Class.new do
      include Schema::Model

      schema_include Schema::Associations::HasOne
      schema_include Schema::Associations::HasMany
      schema_include Schema::Parsers::Hash

      attribute :name, :string, alias: :full_name
      attribute :settings, :hash

      has_one :company do
        attribute :name, :string
      end

      has_many :phones do
        attribute :number, :string
      end
    end
  end
  let(:model) do
    model_class.from_hash(
      name: +'Joe', age: 1, settings: { 'tags' => ['a'] },
      company: { name: 'Acme' }, phones: [{ number: '555' }]
    )
  end
  let(:copy) { model.deep_dup }

  it 'copies the attribute values' do
    expect(copy).to eq(model)
    expect(copy).not_to equal(model)
  end

  it 'copies nested models and collections' do
    copy.name << '!'
    copy.settings['tags'] << 'b'
    copy.company.name = 'Other'
    copy.phones.first.number = '000'
    copy.phones << nil
    expect(model.as_json).to eq(
      name: 'Joe', settings: { 'tags' => ['a'] }, company: { name: 'Acme' }, phones: [{ number: '555' }]
    )
  end

  it 'copies the parsing errors without sharing them' do
    copy.parsing_errors.add(:name, 'invalid')
    expect(model.parsing_errors.errors).to eq(age: ['unknown_attribute'])
    expect(copy.parsing_errors.errors).to eq(age: ['unknown_attribute'], name: ['invalid'])
  end

  it 'keeps which attributes were set' do
    expect(model_class.from_hash(name: 'Joe').deep_dup.settings_was_set?).to eq(false)
  end

  context 'with ActiveModel parsing errors' do
    let(:model_class) do
      kls = Class.new do
        include Schema::All

        attribute :age, :integer
      end
      Object.const_set("ModelClass#{SecureRandom.hex(10)}", kls)
    end
    let(:model) { model_class.from_hash(age: 'x') }

    it 'copies the parsing errors' do
      expect(copy.parsing_errors.full_messages).to eq(['Age is invalid'])
      expect(copy.parsing_errors).not_to equal(model.parsing_errors)
    end
  end
end
