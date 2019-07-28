require 'spec_helper'

describe Schema::Arrays do
  let(:model_class_name) { 'ModelClass' + SecureRandom.hex(10) }
  let(:model_class) do
    kls = Class.new do
      include Schema::Model
      schema_include Schema::Associations::HasOne
      schema_include Schema::Associations::HasMany
      schema_include Schema::Arrays

      attribute :id, :integer
      attribute :name, :string
      attribute :unknown, :string

      has_one :company do
        attribute :name, :string

        has_one :location do
          attribute :city, :string
          attribute :state, :string
        end
      end

      has_many :friends do
        attribute :name, :string
        attribute :status, :string

        has_one :game do
          attribute :name, :string
        end
      end
    end

    Object.const_set(model_class_name, kls)
    Object.const_get(model_class_name)
  end
  let(:mapped_headers) do
    {
      id: {index: 0},
      name: {index: 2},
      company: {
        name: {index: 1},
        location: {
          city: {index: 4},
          state: {index: 3}
        }
      },
      friends: {
        name: {indexes: [5, 7]},
        status: {indexes: [6, 8]},
        game: {
          name: {indexes: [10, 11]}
        }
      }
    }
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
      'Unused Value',
      'Pirates',
      'Swords'
    ]
  end
  let(:model) { model_class.from_array(model_data, mapped_headers) }

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
    expect(model.friends[0].game.name).to eq('Pirates')
    expect(model.friends[1].name).to eq('Frank')
    expect(model.friends[1].status).to eq('Poor')
    expect(model.friends[1].game.name).to eq('Swords')
  end
end
