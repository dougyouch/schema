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

  context '#add_type' do
    it 'item has 2 types' do
      expect(model_class.schema[:item][:types].keys).to eq(['foo', 'bar'])
    end
  end
end
