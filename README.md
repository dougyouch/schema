# Schema

A powerful Ruby gem for data transformation, validation, and type safety. Schema provides a flexible and intuitive way to define data models with support for complex nested structures, dynamic associations, and robust validation.

[![CI](https://github.com/dougyouch/schema/actions/workflows/ci.yml/badge.svg)](https://github.com/dougyouch/schema/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/dougyouch/schema/graph/badge.svg)](https://codecov.io/gh/dougyouch/schema)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'schema-model'
```

And then execute:

```bash
$ bundle install
```

## Quick Start

```ruby
class UserSchema
  include Schema::All

  attribute :name, :string
  attribute :age, :integer
  attribute :email, :string
  attribute :active, :boolean, default: false
  attribute :tags, :array, separator: ',', data_type: :string

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end

user = UserSchema.from_hash(
  name: 'John Doe',
  age: '30',
  email: 'john@example.com',
  active: 'yes',
  tags: 'ruby,rails,developer'
)

user.valid?        # => true
user.name          # => "John Doe"
user.age           # => 30 (parsed to integer)
user.active        # => true (parsed from "yes")
user.tags          # => ["ruby", "rails", "developer"]
```

## Data Types

### Basic Types

```ruby
attribute :name, :string              # String values
attribute :count, :integer            # Integer values (parses "123" to 123)
attribute :price, :float              # Float values (parses "9.99" to 9.99)
attribute :active, :boolean           # Boolean (accepts: 1, t, true, on, y, yes)
attribute :notes, :string_or_nil      # String, but returns nil if empty
```

### Date and Time Types

```ruby
attribute :created_at, :time          # ISO 8601 format (Time.xmlschema)
attribute :birth_date, :date          # Date.parse format
attribute :us_date, :american_date    # MM/DD/YYYY format
attribute :us_time, :american_time    # MM/DD/YYYY HH:MM:SS format
```

### Complex Types

```ruby
attribute :tags, :array                           # Array of values
attribute :tags, :array, separator: ','           # Parse "a,b,c" into ["a","b","c"]
attribute :tags, :array, separator: ',', data_type: :integer  # Parse and convert elements
attribute :metadata, :hash                        # Hash/dictionary values
attribute :config, :json                          # Parse JSON strings
```

## Attribute Options

### Aliases

```ruby
# Single alias
attribute :name, :string, alias: 'FullName'

# Multiple aliases
attribute :name, :string, aliases: [:full_name, :display_name]
```

### Default Values

```ruby
attribute :status, :string, default: 'pending'
attribute :count, :integer, default: 0
attribute :tags, :array, default: []
```

### Checking If Attribute Was Set

Every attribute generates a `_was_set?` predicate method:

```ruby
user = UserSchema.from_hash(name: 'John')
user.name_was_set?   # => true
user.email_was_set?  # => false (not provided)

# Useful for distinguishing "not provided" vs "provided as nil"
user = UserSchema.from_hash(name: nil)
user.name_was_set?   # => true (explicitly set to nil)
```

## Associations

### Has One

```ruby
class OrderSchema
  include Schema::All

  attribute :id, :integer

  has_one :customer do
    attribute :name, :string
    attribute :email, :string
  end
end

order = OrderSchema.from_hash(
  id: 1,
  customer: { name: 'Alice', email: 'alice@example.com' }
)
order.customer.name  # => "Alice"
```

### Has Many

```ruby
class OrderSchema
  include Schema::All

  attribute :id, :integer

  has_many :items do
    attribute :sku, :string
    attribute :quantity, :integer
  end
end

order = OrderSchema.from_hash(
  id: 1,
  items: [
    { sku: 'ABC', quantity: 2 },
    { sku: 'XYZ', quantity: 1 }
  ]
)
order.items.length       # => 2
order.items.first.sku    # => "ABC"
```

### Association Options

```ruby
# Default values - creates empty model/array if not provided
has_one :profile, default: true
has_many :tags, default: true

# Reuse existing schema class
has_one :shipping_address, base_class: AddressSchema
has_one :billing_address, base_class: AddressSchema

# Has many from hash (keyed by field)
has_many :items, from: :hash, hash_key_field: :id do
  attribute :id, :string
  attribute :name, :string
end

# Input: { items: { 'abc' => { name: 'Item 1' }, 'xyz' => { name: 'Item 2' } } }
# Result: items[0].id => 'abc', items[1].id => 'xyz'
```

### Appending to Has Many

```ruby
order = OrderSchema.from_hash(id: 1, items: [])
order.append_to_items(sku: 'NEW', quantity: 5)
order.items.length  # => 1
```

## Dynamic Types

Create different model structures based on a type field:

```ruby
class CompanySchema
  include Schema::All

  has_many :employees, type_field: :type do
    attribute :type, :string
    attribute :name, :string

    add_type('engineer') do
      attribute :programming_languages, :array, separator: ','
    end

    add_type('manager') do
      attribute :department, :string
      attribute :team_size, :integer
    end

    default_type do
      # Fallback for unknown types
    end
  end
end

company = CompanySchema.from_hash(
  employees: [
    { type: 'engineer', name: 'Alice', programming_languages: 'ruby,python' },
    { type: 'manager', name: 'Bob', department: 'Engineering', team_size: 5 }
  ]
)

company.employees[0].programming_languages  # => ["ruby", "python"]
company.employees[1].team_size              # => 5
```

### Dynamic Type Options

```ruby
# Type field within nested data (default)
has_many :items, type_field: :kind do
  # looks for :kind in each item's data
end

# Type determined by parent field
has_one :details, external_type_field: :category do
  # uses parent's :category field to determine type
end

# Case-insensitive type matching
has_many :items, type_field: :type, type_ignorecase: true do
  add_type('widget') { }  # matches "Widget", "WIDGET", etc.
end
```

## Validation and Error Handling

### ActiveModel Validations

```ruby
class UserSchema
  include Schema::All

  attribute :name, :string
  attribute :email, :string
  attribute :age, :integer

  validates :name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :age, numericality: { greater_than: 0 }, allow_nil: true
end
```

### Parsing Errors vs Validation Errors

```ruby
user = UserSchema.from_hash(name: 'John', age: 'not-a-number')

# Parsing errors (type conversion failures)
user.parsing_errors.empty?  # => false
user.parsed?                # => false

# Validation errors (business rules)
user.valid?                 # => false (also runs validations)
user.errors.full_messages   # => ["Age is invalid", ...]
```

### Raising Exceptions

```ruby
user = UserSchema.from_hash(age: 'invalid')

user.parsed!      # raises Schema::ParsingException if parsing errors
user.valid_model! # raises Schema::ValidationException if validation errors
user.valid!       # raises either (checks both)

# Exception includes the model and errors
begin
  user.valid!
rescue Schema::ParsingException => e
  e.schema  # => the model instance
  e.errors  # => the errors object
end
```

### Unknown Attributes

By default, unknown attributes are captured as parsing errors:

```ruby
user = UserSchema.from_hash(name: 'John', unknown_field: 'value')
user.parsing_errors[:unknown_field]  # => ["unknown_attribute"]

# Disable this behavior
UserSchema.capture_unknown_attributes = false
```

## Serialization

### to_hash / as_json

```ruby
user = UserSchema.from_hash(name: 'John', email: nil)

user.to_hash                          # => { name: "John", email: nil }
user.as_json                          # => { name: "John" } (excludes nils)
user.as_json(include_nils: true)      # => { name: "John", email: nil }

# Filter fields
user.as_json(select_filter: ->(name, value, opts) { name == :name })
user.as_json(reject_filter: ->(name, value, opts) { value.nil? })
```

## Protecting Fields with skip_fields

Prevent certain fields from being set by user input:

```ruby
user_data = {
  id: 123,
  name: 'John Doe',
  created_at: '2024-01-01'
}

# Skip database-managed fields
user = UserSchema.from_hash(user_data, [:id, :created_at])

user.id          # => nil (not set)
user.name        # => "John Doe"
user.created_at  # => nil (not set)

# Nested skip_fields for associations
order = OrderSchema.from_hash(data, [:id, { items: [:id] }])
```

## Array and CSV Support

### Schema::Arrays Module

Convert models to/from flat arrays (useful for CSV/spreadsheet data):

```ruby
class UserSchema
  include Schema::All
  schema_include Schema::Arrays

  attribute :name, :string
  attribute :email, :string
end

# Get headers
UserSchema.to_headers  # => ["name", "email"]

# Convert to array
user = UserSchema.from_hash(name: 'John', email: 'john@example.com')
user.to_a  # => ["John", "john@example.com"]

# Create from array
headers = ['name', 'email']
mapped = UserSchema.map_headers_to_attributes(headers)
user = UserSchema.from_array(['Jane', 'jane@example.com'], mapped)
```

### Schema::CSVParser Module

Parse CSV data directly into models:

```ruby
class UserCSVSchema
  include Schema::Model
  include Schema::CSVParser

  attribute :name, :string
  attribute :email, :string
end

csv_data = CSV.parse("name,email\nJohn,john@example.com", headers: true)
parser = Schema::CSVParser.new(csv_data, UserCSVSchema)

parser.each do |user|
  puts user.name
end
```

### Schema::ArrayHeaders Module

Map CSV/array headers to schema attributes:

```ruby
class UserSchema
  include Schema::All
  schema_include Schema::ArrayHeaders

  attribute :name, :string, alias: 'FullName'
  attribute :email, :string
end

headers = ['FullName', 'email', 'unknown_column']
mapped = UserSchema.map_headers_to_attributes(headers)
# => { name: { index: 0 }, email: { index: 1 } }

UserSchema.get_mapped_field_names(mapped)    # => ["name", "email"]
UserSchema.get_unmapped_field_names(mapped)  # => []
```

## Extending Schemas

### schema_include

Add modules to a schema and all its nested associations:

```ruby
class OrderSchema
  include Schema::All

  has_many :items do
    attribute :name, :string
  end
end

# Add Arrays support to OrderSchema and OrderSchema::SchemaHasManyItems
OrderSchema.schema_include Schema::Arrays
```

## CLI Tools

### schema-json2csv

Convert JSON data to CSV using a schema:

```bash
# Basic usage
schema-json2csv --require ./my_schema.rb --schema MySchema --json data.json --csv output.csv

# From stdin
cat data.json | schema-json2csv --require ./my_schema.rb --schema MySchema - --csv output.csv
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
