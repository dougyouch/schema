# frozen_string_literal: true

# Example that show cases multiple features
class CompanySchema
  # includes model, associations, parsers and active model validations
  include Schema::All

  # add common attributes
  # attributes support additional names through the alias(es) option
  attribute :name, :string, alias: 'CompanyName'
  attribute :industry_type, :string, aliases: %w[IndustryType industry]

  # will take a string split on the separator and use the parse_<data_type> method on every element
  # basically take a list of comma separated numbers and create an array of integers
  # code snippet: str.split(',').map { |v| parse_integer(field_name, parsing_errors, v) }
  attribute :number_list, :array, separator: ',', data_type: :integer

  # creates a nested dynamic schema based on the industry_type which is part of the main company data
  industry_schema = has_one(:industry, external_type_field: :industry_type) do
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

  # create multiple dynamic location schemas based on the type field in the location data
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

  # create multiple dynamic employee schemas based on the type field in the employee data
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
    # if no or an invalid type is specified, create a default employee schema object
    # useful for communicating errors in an API
    default_type

    # dynamic_type_names returns all the types used, except for :default
    validates :type, inclusion: { in: dynamic_type_names }
  end

  has_many(:admins, from: :hash, hash_key_field: :username) do
    attribute :username, :string
    attribute :email, :string
    attribute :name, :string

    validates :username, presence: true
    validates :email, presence: true
  end

  validates :name, presence: true
  validates :industry_type, inclusion: { in: industry_schema.dynamic_type_names }

  # use the schema validator
  validates :industry, presence: true, schema: true
  validates :locations, presence: true, schema: true
  validates :employees, presence: true, schema: true
  validates :admins, presence: true, schema: true
end
