# frozen_string_literal: true

require 'spec_helper'

describe Schema::ArrayHeaders do
  let(:model_class_name) { "ModelClass#{SecureRandom.hex(10)}" }
  let(:model_class) do
    kls = Class.new do
      include Schema::Model

      schema_include Schema::Associations::HasOne
      schema_include Schema::Associations::HasMany
      schema_include Schema::ArrayHeaders
      schema_include Schema::Arrays

      attribute :id, :integer, aliases: ['ID']
      attribute :name, :string, aliases: ['PersonName']
      attribute :unknown, :string

      has_one :company do
        attribute :name, :string, aliases: ['CompanyName']

        has_one :location do
          attribute :city, :string, aliases: ['CompanyCity']
          attribute :state, :string, aliases: ['CompanyStateCode']
          attribute :country, :string, aliases: ['CompanyCountry']
        end
      end

      has_many :friends, aliases: ['Friends'] do
        attribute :name, :string, aliases: ['Name']
        attribute :status, :string, aliases: ['Status']

        has_one :game do
          attribute :name, :string, aliases: ['FavoriteGameName']
          attribute :high_score, :integer, aliases: ['HighScore']
        end
      end
    end

    kls.map_headers_to_attributes(model_data_headers)

    Object.const_set(model_class_name, kls)
    Object.const_get(model_class_name)
  end
  let(:model_data_headers) do
    %w[
      ID
      CompanyName
      PersonName
      CompanyStateCode
      CompanyCity
      Friends1Name
      Friends1Status
      Friends2Name
      Friends2Status
      NotUsed
      Friends1FavoriteGameName
      Friends2FavoriteGameName
      Friends3FavoriteGameName
    ]
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
      'Swords',
      'Ninja'
    ]
  end
  let(:mapped_headers) { model_class.map_headers_to_attributes(model_data_headers) }
  let(:model) { model_class.from_array(model_data, mapped_headers) }

  subject { model }

  it 'uses the index values to assign elmeents from the array' do
    expect(model.id).to eq(4)
    expect(model.name).to eq('Joe Smith')
    expect(model.company.name).to eq('Paper INC')
    expect(model.company.location.city).to eq('Nowhere')
    expect(model.company.location.state).to eq('UU')
    expect(model.friends[0].name).to eq('Jimmy')
    expect(model.friends[0].status).to eq('Good')
    expect(model.friends[0].game.name).to eq('Pirates')
    expect(model.friends[1].name).to eq('Frank')
    expect(model.friends[1].status).to eq('Poor')
    expect(model.friends[1].game.name).to eq('Swords')
    expect(model.friends[2].name).to eq(nil)
    expect(model.friends[2].status).to eq(nil)
    expect(model.friends[2].game.name).to eq('Ninja')
  end

  context 'get_unmapped_field_names' do
    it 'returns list of unmapped fields' do
      expect(subject.class.get_unmapped_field_names(mapped_headers)).to eq(%w[unknown CompanyCountry FriendsXHighScore])
    end
  end

  context 'get_mapped_field_names' do
    it 'returns list of mapped fields' do
      expect(subject.class.get_mapped_field_names(mapped_headers)).to eq(%w[ID PersonName CompanyName CompanyCity CompanyStateCode FriendsXName FriendsXStatus FriendsXFavoriteGameName])
    end
  end
end
