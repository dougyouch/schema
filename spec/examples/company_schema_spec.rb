require 'spec_helper'

# file: app/schemas/company_schema.rb

class CompanySchema
  # changes the class to a schema model, adds the attribute method and include common types
  include Schema::Model

  # includes ActiveModel::Validations and changes parsing_errors to ActiveModel::Errors
  include Schema::ActiveModelValidations

  # adds nested schemas
  include Schema::Associations::HasOne
  include Schema::Associations::HasMany

  # adds the array attribute
  include Schema::Parsers::Array

  # adds the hash attribute
  include Schema::Parsers::Hash

  attribute :name, :string
  attribute :industry_type, :string

  # will take a string split on the separator and use the parse_integer method on every element
  # basically take a list of comma separated numbers and create an array of integers
  # str.split(',').map { |v| parse_integer(v) }
  attribute :number_list, :array, separator: ',', data_type: :integer

  industry_assoc = has_one(:industry, external_type_field: :industry_type) do
    attribute :name, :string

    validates :name, presence: true

    add_type('tech') do
      attribute :custom_description, :string
    end

    add_type('qsr') do
      attribute :number_of_locations, :integer

      # custom validation
      validates :number_of_locations, presence: true
    end
  end

  has_many(:locations, type_field: :type) do
    attribute :type, :string
    attribute :address, :string
    attribute :city, :string
    attribute :state, :string
    attribute :zip, :string

    add_type('headquarters') do
      attribute :main_floor, :integer

      validates :city, presence: true
      validates :main_floor, presence: true
    end

    add_type('store_front') do
      attribute :main_entrance, :string

      validates :address, presence: true
      validates :main_entrance, presence: true
    end
  end

  has_many(:employees, type_field: :type) do
    attribute :type, :integer
    attribute :name, :string
    attribute :start_date, :date
    add_type(1) do # worker
      attribute :manager_name, :string
    end
    add_type(2) do # manager
      attribute :rank, :float
    end
    # if no or invalid type is specified
    add_type(:default)

    validates :type, inclusion: {in: dynamic_type_names}
  end

  validates :name, presence: true
  validates :industry_type, inclusion: {in: industry_assoc.dynamic_type_names}
  validates :industry, presence: true, schema: true
  validates :locations, presence: true, schema: true
  validates :employees, presence: true, schema: true
end

describe 'CompanySchema example' do
  let(:payload) do
    {
      name: 'Good Burger',
      industry_type: 'qsr',
      industry: {
        name: 'Food & Beverage',
        number_of_locations: 2
      },
      locations: [
        {
          type: 'headquarters',
          city: 'Boston',
          main_floor: 5
        },
        {
          type: 'store_front',
          address: '1st Ave',
          zip: '02211',
          main_entrance: 'side door'
        }
      ],
      employees: [
        {
          type: 2,
          name: 'Queen Bee',
          start_date: '2016-01-09',
          rank: '0.9'
        },
        {
          type: 1,
          name: 'Worker Bee',
          start_date: '2018-05-10',
          manager_name: 'Queen Bee'
        }
      ]
    }
  end
  let(:company_schema) { CompanySchema.from_hash(payload) }

  describe 'valid?' do
    subject { company_schema.valid? }

    it 'return true' do
      expect(subject).to eq(true)
      expect(company_schema.parsing_errors.empty?).to eq(true)
    end

    describe 'invalid' do
      before(:each) do
        payload[:employees].first.delete(:type)
      end

      it 'return false' do
        expect(subject).to eq(false)
        expect(company_schema.parsing_errors.empty?).to eq(false)
      end

      it 'employees have errors' do
        subject
        expect(company_schema.errors[:employees]).to eq(['is invalid'])
        expect(company_schema.employees.first.errors[:type]).to eq(['is not included in the list'])
      end
    end
  end
end
