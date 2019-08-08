# schema

Fast and easy way to transform data into models for validation and type safety.

[![Build Status](https://travis-ci.org/dougyouch/schema.svg?branch=master)](https://travis-ci.org/dougyouch/schema)
[![Maintainability](https://api.codeclimate.com/v1/badges/c142d46a7a37d4a8c2e5/maintainability)](https://codeclimate.com/github/dougyouch/schema/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/c142d46a7a37d4a8c2e5/test_coverage)](https://codeclimate.com/github/dougyouch/schema/test_coverage)

Attributes of a model have a name and type.  Any value passed in goes through a parser method.  If the value can not be parsed successfully the error is added to parsing_errors.

Associations are nested schema models.  Each association can have its own set of attributes.

Dynamic associations are useful when creating custom logic around schema validation.

#### Example that show cases multiple features

###### spec/examples/company_schema.rb
```ruby
# frozen_string_literal: true

# Example that show cases multiple features
class CompanySchema
  # changes the class to a schema model, adds the attribute method and includes common types
  include Schema::Model

  # includes ActiveModel::Validations and changes parsing_errors to ActiveModel::Errors
  include Schema::ActiveModelValidations

  # schema_include is used to add include(s) to associated schemas,
  # keeps you from having to re-add same includes for every has_one or has_many

  # adds nested schemas
  schema_include Schema::Associations::HasOne
  schema_include Schema::Associations::HasMany

  # adds the array attribute
  schema_include Schema::Parsers::Array

  # adds the hash attribute
  schema_include Schema::Parsers::Hash

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

  validates :name, presence: true
  validates :industry_type, inclusion: { in: industry_schema.dynamic_type_names }

  # use the schema validator
  validates :industry, presence: true, schema: true
  validates :locations, presence: true, schema: true
  validates :employees, presence: true, schema: true
end
```

###### spec/examples/company_schema.json
```javascript
{
  "CompanyName": "Good Burger",
  "IndustryType": "qsr",
  "industry": {
    "name": "Food & Beverage",
    "number_of_locations": 2
  },
  "locations": [
    {
      "type": "headquarters",
      "city": "Boston",
      "main_floor": 5
    },
    {
      "type": "store_front",
      "address": "1st Ave",
      "zip": "02211",
      "main_entrance": "side door"
    }
  ],
  "employees": [
    {
      "type": 2,
      "name": "Queen Bee",
      "start_date": "2016-01-09",
      "rank": "0.9"
    },
    {
      "type": 1,
      "name": "Worker Bee",
      "start_date": "2018-05-10",
      "manager_name": "Queen Bee"
    }
  ]
}
```
