require 'spec_helper'

describe Schema::Arrays do
  let(:model_class_name) { 'ModelClass' + SecureRandom.hex(10) }
  let(:model_class) do
    kls = Class.new do
      include Schema::Model
      schema_include Schema::Relation::HasOne
      schema_include Schema::Relation::HasMany
      schema_include Schema::Arrays

      attribute :id, :integer, index: 0
      attribute :name, :string, index: 2
      attribute :unknown, :string

      has_one :company do
        attribute :name, :string, index: 1

        has_one :location do
          attribute :city, :string, index: 4
          attribute :state, :string, index: 3
        end
      end

      has_many :friends, size: 2 do
        attribute :name, :string, indexes: [5, 7]
        attribute :status, :string, indexes: [6, 8]
      end
    end

    Object.const_set(model_class_name, kls)
    Object.const_get(model_class_name)
  end
  let(:model_data) do
    [
      '4',
      'Paper INC',
      'Joe Smith',
      'UU',
      'Nowhere',
      'Jimmy',
      'Good',
      'Frank',
      'Poor',
      'Unused Value'
    ]
  end
  let(:model) { model_class.from_array(model_data) }

  subject { model }

  it 'uses the index values to assign elmeents from the array' do
    expect(model.id).to eq(4)
    expect(model.name).to eq('Joe Smith')
    expect(model.unknown).to eq(nil)
    expect(model.company.name).to eq('Paper INC')
    expect(model.company.location.city).to eq('Nowhere')
    expect(model.company.location.state).to eq('UU')
    expect(model.friends[0].name).to eq('Jimmy')
    expect(model.friends[0].status).to eq('Good')
    expect(model.friends[1].name).to eq('Frank')
    expect(model.friends[1].status).to eq('Poor')
  end
end
