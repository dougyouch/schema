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

      has_many :friends, size: 3 do
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

  context '.to_empty_array' do
    subject { model_class.to_empty_array }
    let(:expected_array) do
      [
        nil, # :id
        nil, # :name
        nil, # :unknown
        [ # company
          nil, # :name
          [ # location
            nil, # :city
            nil  #: state
          ]
        ],
        [ # 3 sets of friends
          [ # friend 1
            nil, # :name
            nil, # :status
            [ # game
              nil # :name
            ]
          ],
          [nil, nil, [nil]], # friend 2
          [nil, nil, [nil]]  # friend 3
        ]
      ]
    end

    it 'returns empty arrays for all attributes' do
      expect(subject).to eq(expected_array)
    end
  end

  context '#to_a' do
    subject { model.to_a }
    let(:expected_array) do
      [
        4, # :id
        "Joe Smith", # :name
        nil, # :unknown
        [ # company
          "Paper INC", # :name
          [ # location
            "Nowhere", # :city
            "UU" # :state
          ]
        ],
        [ # 3 sets of friends
          [ # friend 1
            "Jimmy", # :name
            "Good",  # :status
            [ # game
              "Pirates" # :name
            ]
          ],
          ["Frank", "Poor", ["Swords"]], # friend 2
          [nil, nil, [nil]] # friend 3
        ]
      ]
    end

    it 'returns schema data as an array' do
      expect(subject).to eq(expected_array)
    end

    describe 'without association data' do
      let(:model_data) do
        [
          '4',
          nil,
          'Joe Smith',
          nil,
          nil,
          nil,
          nil,
          nil,
          nil,
          nil,
          nil,
          nil
        ]
      end
      let(:expected_array) do
        [
          4, # :id
          'Joe Smith', # :name
          nil, # :unknown
          [ # company
            nil, # :name
            [ # location
              nil, # :city
              nil  #: state
            ]
          ],
          [ # 3 sets of friends
            [ # friend 1
              nil, # :name
              nil, # :status
              [ # game
                nil # :name
              ]
            ],
            [nil, nil, [nil]], # friend 2
            [nil, nil, [nil]]  # friend 3
          ]
        ]
      end

      it 'returns empty arrays for all attributes' do
        expect(subject).to eq(expected_array)
      end
    end
  end

  context '.to_headers' do
    subject { model_class.to_headers }
    let(:expected_array) do
      [
        "id",
        "name",
        "unknown",
        "company.name",
        "company.location.city",
        "company.location.state",
        "friends[1].name",
        "friends[1].status",
        "friends[1].game.name",
        "friends[2].name",
        "friends[2].status",
        "friends[2].game.name",
        "friends[3].name",
        "friends[3].status",
        "friends[3].game.name"
      ]
    end

    it 'returns headers as a flat array' do
      expect(subject).to eq(expected_array)
    end
  end
end
