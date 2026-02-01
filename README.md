# Schema

A powerful Ruby gem for data transformation, validation, and type safety. Schema provides a flexible and intuitive way to define data models with support for complex nested structures, dynamic associations, and robust validation.

[![CI](https://github.com/dougyouch/schema/actions/workflows/ci.yml/badge.svg)](https://github.com/dougyouch/schema/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/dougyouch/schema/graph/badge.svg)](https://codecov.io/gh/dougyouch/schema)

## Features

- **Type Safety**: Strong typing with automatic parsing and validation
- **Flexible Attributes**: Support for aliases and custom data types
- **Nested Models**: Complex data structures with nested associations
- **Dynamic Associations**: Runtime type-based model creation
- **ActiveModel Integration**: Seamless integration with ActiveModel validations
- **Error Handling**: Comprehensive error collection and reporting
- **CSV Support**: Built-in CSV parsing capabilities

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

Here's a simple example to get you started:

```ruby
class UserSchema
  include Schema::All

  attribute :name, :string
  attribute :age, :integer
  attribute :email, :string
  attribute :tags, :array, separator: ',', data_type: :string

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end

# Usage
user_data = {
  name: 'John Doe',
  age: '30',
  email: 'john@example.com',
  tags: 'ruby,rails,developer'
}

user = UserSchema.from_hash(user_data)
if user.valid?
  puts "User created: #{user.name}"
else
  puts "Validation errors: #{user.errors.full_messages}"
end
```

## Core Concepts

### Attributes

Attributes define the structure of your data model. Each attribute has:
- A name
- A type
- Optional aliases
- Custom parsing rules

```ruby
attribute :name, :string, alias: 'FullName'
attribute :age, :integer
attribute :tags, :array, separator: ',', data_type: :string
```

### Associations

Schema supports various types of associations:

1. **Has One**: Single nested model
2. **Has Many**: Multiple nested models
3. **Dynamic Associations**: Type-based model creation

```ruby
has_one(:profile) do
  attribute :bio, :string
  attribute :website, :string
end

has_many(:posts) do
  attribute :title, :string
  attribute :content, :string
end
```

### Dynamic Types

Create different model structures based on a type field:

```ruby
has_many(:vehicles, type_field: :type) do
  attribute :type, :string
  attribute :color, :string

  add_type('car') do
    attribute :doors, :integer
  end

  add_type('truck') do
    attribute :bed_length, :float
  end
end
```

## Advanced Features

### Custom Parsers

Define custom parsing logic for your attributes:

```ruby
attribute :custom_field, :custom_type do
  def parse_custom_type(field_name, errors, value)
    # Custom parsing logic
  end
end
```

### CSV Integration

Parse CSV data directly into your models:

```ruby
class UserCSVSchema
  include Schema::CSVParser
  
  attribute :name, :string
  attribute :email, :string
end

users = UserCSVSchema.parse_csv(csv_data)
```

## Using `skip_fields` to Protect Internal Fields

When instantiating a schema with `from_hash`, you can use the `skip_fields` argument to prevent certain fields (such as `id`, `created_at`, `updated_at`) from being set by user input. This is especially useful for fields managed by the database or internal logic, ensuring end users cannot override these values.

**Example:**

```ruby
user_data = {
  id: 123, # Should be managed by DB
  name: 'John Doe',
  email: 'john@example.com',
  created_at: '2024-06-01T12:00:00Z', # Should be managed by DB
  updated_at: '2024-06-01T12:00:00Z'  # Should be managed by DB
}

# Skip DB-managed fields
user = UserSchema.from_hash(user_data, [:id, :created_at, :updated_at])

puts user.id          # => nil (not set from user input)
puts user.created_at  # => nil (not set from user input)
puts user.updated_at  # => nil (not set from user input)
puts user.name        # => 'John Doe'
```

**Benefit:**
- Prevents end users from setting or changing internal DB values.
- Ensures only safe, intended fields are settable from external input.
- Helps maintain data integrity and security in your application.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

