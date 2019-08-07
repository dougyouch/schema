# Example that show cases multiple features
class CompanySchema
  # changes the class to a schema model, adds the attribute method and includes common types
  include Schema::Model

  # includes ActiveModel::Validations and changes parsing_errors to ActiveModel::Errors
  include Schema::ActiveModelValidations

  # adds nested schemas
  schema_include Schema::Associations::HasOne
  schema_include Schema::Associations::HasMany

  # adds the array attribute
  schema_include Schema::Parsers::Array

  # adds the hash attribute
  schema_include Schema::Parsers::Hash

  attribute :name, :string
  attribute :industry_type, :string

  # will take a string split on the separator and use the parse_<data_type> method on every element
  # basically take a list of comma separated numbers and create an array of integers
  # code snippet: str.split(',').map { |v| parse_integer(field_name, parsing_errors, v) }
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

    # dynamic_type_names returns all the types used, except for :default
    validates :type, inclusion: {in: dynamic_type_names}
  end

  validates :name, presence: true
  validates :industry_type, inclusion: {in: industry_assoc.dynamic_type_names}

  # use the schema validator
  validates :industry, presence: true, schema: true
  validates :locations, presence: true, schema: true
  validates :employees, presence: true, schema: true
end
