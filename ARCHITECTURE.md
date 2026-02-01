# Architecture

This document describes the internal architecture of the `schema-model` gem.

## Overview

The gem transforms hash data into strongly-typed Ruby objects with parsing, validation, and nested associations. The core flow is:

```
Hash Data → from_hash() → Parser Methods → Schema Instance
                              ↓
                      parsing_errors (if invalid)
```

## Module Hierarchy

```
Schema::All (convenience bundle)
    ├── Schema::Model (core attribute system)
    ├── Schema::Associations::HasOne
    ├── Schema::Associations::HasMany
    ├── Schema::Parsers::Common
    ├── Schema::Parsers::American
    ├── Schema::Parsers::Array
    ├── Schema::Parsers::Hash
    ├── Schema::Parsers::Json
    └── Schema::ActiveModelValidations
```

## Core Components

### Schema::Model (`lib/schema/model.rb`)

The foundation module providing:

- **`attribute(name, type, options)`**: Defines schema fields. Each call:
  1. Adds field metadata to the class's `schema` hash via `add_value_to_class_method`
  2. Generates getter, setter, and `<name>_was_set?` methods
  3. Setter invokes `parse_<type>` method automatically

- **`from_hash(data, skip_fields)`**: Class method that creates instance and calls `update_attributes`

- **`update_attributes(data, skip_fields)`**: Iterates hash keys, matches against schema, invokes setters

- **`as_json` / `to_hash`**: Serialization back to hash format

### Schema::Parsers::Common (`lib/schema/parsers/common.rb`)

Base parser methods for fundamental types:
- `parse_integer`, `parse_float`, `parse_string`, `parse_string_or_nil`
- `parse_boolean`, `parse_time`, `parse_date`

Each parser:
1. Accepts `(field_name, parsing_errors, value)`
2. Returns converted value or nil
3. Adds to `parsing_errors` on failure (never raises)

Additional parsers extend these: `Parsers::American` (date formats), `Parsers::Array`, `Parsers::Hash`, `Parsers::Json`.

### Schema::Associations (`lib/schema/associations/`)

**HasOne** and **HasMany** define nested relationships:

```ruby
has_one(:profile) { attribute :bio, :string }
has_many(:posts) { attribute :title, :string }
```

Both use **SchemaCreator** (`schema_creator.rb`) to:
1. Determine which class to instantiate (static or dynamic)
2. Call `from_hash` on the nested class
3. Propagate parsing errors to parent

**DynamicTypes** enables polymorphic associations:

```ruby
has_many(:items, type_field: :kind) do
  add_type('widget') { attribute :size, :integer }
  add_type('gadget') { attribute :power, :float }
  default_type { } # fallback
end
```

The `type_field` option tells SchemaCreator which data key determines the subclass.

### Schema::Utils (`lib/schema/utils.rb`)

Utility methods for:
- `classify_name`: String → ClassName conversion
- `create_schema_class`: Dynamically creates nested schema classes
- `add_association_class`: Wires up association with proper modules
- `add_attribute_default_methods` / `add_association_default_methods`: Default value handling

### Error Handling

Two error storage mechanisms:

1. **Schema::Errors** (`lib/schema/errors.rb`): Simple hash-based storage, used standalone

2. **ActiveModel::Errors**: When `Schema::ActiveModelValidations` is included, `parsing_errors` returns `ActiveModel::Errors` instance

Parsing errors are distinct from validation errors:
- **Parsing errors**: Type conversion failures (string "abc" → integer)
- **Validation errors**: Business rule failures (via `validates` DSL)

Methods `parsed!` and `valid!` raise `ParsingException`/`ValidationException` respectively.

### Inheritance Helper Integration

The gem uses `inheritance-helper` for schema inheritance. Key method:
- `add_value_to_class_method(:schema, name => options)`: Accumulates schema definitions across class hierarchy

This allows schema classes to inherit attributes from parent classes.

## Data Flow Example

```ruby
class OrderSchema
  include Schema::All
  attribute :total, :float
  has_one(:customer) { attribute :name, :string }
end

order = OrderSchema.from_hash({
  total: "99.50",
  customer: { name: "Alice" }
})
```

1. `from_hash` calls `new.update_attributes(data)`
2. `update_attributes` iterates keys, finds `:total` in schema
3. Calls `self.total = "99.50"` → invokes `parse_float`
4. For `:customer`, recognizes association, delegates to SchemaCreator
5. SchemaCreator calls `OrderSchema::SchemaHasOneCustomer.from_hash({name: "Alice"})`
6. Returns populated `OrderSchema` instance
