# Schema

A powerful Ruby gem for data transformation, validation, and type safety. Schema provides a flexible and intuitive way to define data models with support for complex nested structures, dynamic associations, and robust validation.

[![CI](https://github.com/dougyouch/schema/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/dougyouch/schema/actions/workflows/ci.yml)
[![Coverage](https://raw.githubusercontent.com/dougyouch/schema/badges/coverage.svg)](https://github.com/dougyouch/schema/actions/workflows/ci.yml)
[![Branch Coverage](https://raw.githubusercontent.com/dougyouch/schema/badges/branches.svg)](https://github.com/dougyouch/schema/actions/workflows/ci.yml)

## Installation

Requires Ruby 3.2 or newer. Add this line to your application's Gemfile:

```ruby
gem 'schema-model'

# needed for Schema::All and Schema::ActiveModelValidations (already present in Rails apps)
gem 'activemodel'

# needed for Schema::CSVParser and bin/schema-json2csv on Ruby 3.4+, where csv is no longer a default gem
gem 'csv'
```

And then execute:

```bash
$ bundle install
```

`Schema::Model` on its own has no dependencies beyond `inheritance-helper`.

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
attribute :count, :integer            # Integer values (parses "123", " 123 " and "0123" to 123)
attribute :price, :float              # Float values (parses "9.99" to 9.99, also "1e+5")
attribute :active, :boolean           # see below
attribute :notes, :string_or_nil      # String, but returns nil if empty
```

Booleans accept `1, t, true, on, y, yes` as `true` and `0, f, false, off, n, no` as `false` (any case). Any other string is an `invalid` parsing error, and numbers are `true` unless they're 0.

For `:integer`, `:float`, `:boolean`, `:date`, `:time`, `:american_date` and `:american_time`, strings are stripped first and a blank string parses to `nil` without an error, so empty CSV cells don't count as bad input.

### Date and Time Types

```ruby
attribute :created_at, :time          # ISO 8601 date and time (Time.xmlschema)
attribute :birth_date, :date          # ISO 8601 (Date.iso8601), e.g. "2024-01-31"; free text like "May 1" is invalid
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

Each type `:foo` is parsed by a `parse_foo` method, so you can add types by defining that method on the model or in a module you `schema_include`. Setting a value on an attribute whose type has no parser raises `Schema::UnknownTypeError` naming the attribute and the missing method.

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
attribute :starts_on, :date, default: Date.new(2024, 1, 1)
```

Each read of a default returns a fresh copy (frozen values are shared), so mutating it doesn't change the default for other instances.

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

# Aliases for the association key
has_one :profile, alias: :user_profile
has_many :items, aliases: [:line_items]

# Reuse existing schema class
has_one :shipping_address, base_class: AddressSchema
has_one :billing_address, base_class: AddressSchema

# Name the generated class (defaults to SchemaHasOneProfile, SchemaHasManyItems, ...)
has_one :profile, class_name: 'ProfileSchema' do
  attribute :bio, :string
end

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
  # looks for :kind in each item's data, or an alias of the kind attribute
  attribute :kind, :string, alias: :category
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

When the type matches no `add_type` and there is no `default_type`, the association is `nil` and the parent records an `unknown` parsing error.

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

Parsing errors and validation errors are tracked separately. `valid?` only runs validations, so check `parsed?` too (or call `valid!`, which checks both). `parsed?` and `parsed!` are available on every `Schema::Model`, not only with ActiveModel.

```ruby
user = UserSchema.from_hash(name: 'John', email: 'john@example.com', age: 'not-a-number')

# Parsing errors (type conversion failures)
user.parsing_errors.empty?  # => false
user.parsed?                # => false
user.age                    # => nil

# Validation errors (business rules)
user.valid?                 # => true (age is nil, which allow_nil permits)
user.errors.full_messages   # => []
```

With `Schema::All` (or `Schema::ActiveModelValidations`), `parsing_errors` is an `ActiveModel::Errors` with readable messages:

```ruby
user.parsing_errors.full_messages  # => ["Age is invalid"]
```

| Code | Message | I18n key |
|---|---|---|
| `invalid` | is invalid | `schema.parsing_errors.invalid` |
| `incompatible` | is an incompatible type | `schema.parsing_errors.incompatible` |
| `unknown` | has an unknown type | `schema.parsing_errors.unknown` |
| `unknown_attribute` | is an unknown attribute | `schema.parsing_errors.unknown_attribute` |
| `unhandled_type` | is an unhandled type | `schema.parsing_errors.unhandled_type` |

A plain `Schema::Model` uses `Schema::Errors`, which stores the codes themselves (`user.parsing_errors[:age] # => ["invalid"]`).

### Validating Nested Schemas

`validates ..., schema: true` (`SchemaValidator`) marks the parent invalid when a nested model, or any model in a has-many list, is invalid:

```ruby
class OrderSchema
  include Schema::All

  has_one :customer do
    attribute :name, :string
    validates :name, presence: true
  end

  validates :customer, presence: true, schema: true
end
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
user.parsing_errors[:unknown_field]  # => ["is an unknown attribute"]

# Disable this behavior
UserSchema.capture_unknown_attributes = false
```

The setting also applies to nested association classes, including ones declared after it is set.

## Serialization

### to_hash / as_json

```ruby
class ContactSchema
  include Schema::All

  attribute :name, :string
  attribute :email, :string
end

user = ContactSchema.from_hash(name: 'John', email: nil)

user.to_hash                          # => { name: "John", email: nil }
user.as_json                          # => { name: "John" } (excludes nils)
user.as_json(include_nils: true)      # => { name: "John", email: nil }

# Filter fields
user.as_json(select_filter: ->(name, value, opts) { name == :name })
user.as_json(reject_filter: ->(name, value, opts) { value.nil? })
```

### Comparing, Inspecting and Copying

```ruby
a = ContactSchema.from_hash(name: 'John')
b = ContactSchema.from_hash('name' => 'John')

a == b               # => true (same class and attribute values, nested models included)
a.attribute_values   # => { name: "John", email: nil }
a.inspect            # => #<ContactSchema name: "John"> (only attributes that were set)

copy = a.deep_dup    # copies nested models, arrays, hashes, strings and parsing errors
copy.name << '!'
a.name               # => "John"
```

`dup` is Ruby's shallow copy, so nested models are shared with the original.

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

# Skip an association entirely
order = OrderSchema.from_hash(data, [:items])
```

A skipped field is ignored whether the data uses symbol keys, string keys, or one of the field's aliases.

## Array and CSV Support

### Schema::Arrays Module

Convert models to/from flat arrays (useful for CSV/spreadsheet data). `from_array` takes the header mapping built by `Schema::ArrayHeaders`, so include both:

```ruby
class UserSchema
  include Schema::All
  schema_include Schema::ArrayHeaders
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

`to_headers`, `to_empty_array` and `to_a` need a fixed number of columns for each has-many association, so give it a `size`:

```ruby
has_many :phones, size: 3 do
  attribute :number, :string
end

UserSchema.to_headers  # => [..., "phones[1].number", "phones[2].number", "phones[3].number"]
```

`to_a` writes at most `size` entries: a model with more entries than that has the extra ones left out of the array, with no error, so pick a `size` large enough for your data.

### Schema::CSVParser

`Schema::CSVParser` is a class that reads rows from a `CSV` object into models. The model needs `Schema::ArrayHeaders` and `Schema::Arrays`. Pass a plain `CSV` (not one created with `headers: true`); the first row is used as the headers unless you pass them in:

```ruby
require 'csv'

class UserCSVSchema
  include Schema::All
  schema_include Schema::ArrayHeaders
  schema_include Schema::Arrays

  attribute :name, :string
  attribute :email, :string
end

csv = CSV.new("name,email\nJohn,john@example.com\n")
parser = Schema::CSVParser.new(csv, UserCSVSchema)

parser.missing_fields(%w[name email phone])  # => ["phone"]

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

# Field names are reported by their first alias when they have one
UserSchema.get_mapped_field_names(mapped)    # => ["FullName", "email"]
UserSchema.get_unmapped_field_names(mapped)  # => []
```

Has-many columns are matched by the association name (or its aliases) followed by a 1-based index and the field key, e.g. `Phones1Number`, `Phones2Number` for `has_many :phones, alias: 'Phones'` with `attribute :number, :string, alias: 'Number'`.

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

The JSON can be one object or an array of objects. Output goes to stdout when `--csv` is omitted. A header row (from `to_headers`) is written to stdout or to a new file; an existing `--csv` file is appended to without repeating it. Has-many associations need a `size:` so every row has the same columns.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
