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
    │     └── Schema::Parsers::Common
    ├── Schema::Associations::HasOne
    ├── Schema::Associations::HasMany
    ├── Schema::Parsers::American
    ├── Schema::Parsers::Array
    ├── Schema::Parsers::Hash
    ├── Schema::Parsers::Json
    └── Schema::ActiveModelValidations

Opt-in (via schema_include):
    ├── Schema::ArrayHeaders (map CSV headers to attributes)
    └── Schema::Arrays (models to/from flat arrays)

Standalone:
    ├── Schema::CSVParser (class; reads CSV rows into models)
    └── SchemaValidator (ActiveModel validator for `schema: true`)
```

`schema_include` both includes a module and records it in `schema_config[:schema_includes]`, so it is also included in every nested association class, including ones defined later.

## Core Components

### Schema::Model (`lib/schema/model.rb`)

The foundation module providing:

- **`attribute(name, type, options)`**: Defines schema fields. Each call:
  1. Adds field metadata to the class's `schema` hash via `add_value_to_class_method`
  2. Generates getter, setter, and `<name>_was_set?` methods
  3. Setter invokes `parse_<type>` method automatically

- **`from_hash(data, skip_fields)`**: Class method that creates instance and calls `update_attributes`

- **`update_attributes(data, skip_fields)`**: Iterates the data's key/value pairs, matches them against the schema, and invokes setters. Plain attributes are set before associations, so an association's `external_type_field` can read a sibling attribute. Each key is looked up on its own: symbol keys in `schema`, anything else in `schema_with_string_keys` (rebuilt whenever `schema` changes). `skip_fields` entries match a field by name or alias, as a symbol or string; a `{ association: [...] }` entry passes a nested list down.

- **Aliases**: each alias adds a second schema entry with `alias_of:` pointing at the real attribute, plus aliased getter/setter methods. Serialization and array conversion skip entries with `alias_of`.

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

Each association gets a generated class (`SchemaHasOne<Name>` / `SchemaHasMany<Name>` by default, or `class_name:`), defined as a constant inside the parent class. `base_class:` subclasses an existing schema instead of creating a fresh model class.

Both use **SchemaCreator** (`schema_creator.rb`) to:
1. Determine which class to instantiate (static or dynamic)
2. Call `from_hash` on the nested class
3. Propagate parsing errors to parent: `invalid` when the nested model has parsing errors, `incompatible` when the value isn't a hash (or, for has-many, an array), and `unknown` when no dynamic type matches

`has_many ..., from: :hash` accepts a hash keyed by id instead of an array; each key is written to `hash_key_field` (default `:id`) on the nested model.

**DynamicTypes** enables polymorphic associations:

```ruby
has_many(:items, type_field: :kind) do
  add_type('widget') { attribute :size, :integer }
  add_type('gadget') { attribute :power, :float }
  default_type { } # fallback
end
```

The `type_field` option tells SchemaCreator which key in the nested data determines the subclass (the type field attribute's aliases are checked too); `external_type_field` reads the type from an attribute on the parent instead. `type_ignorecase: true` compares type names case-insensitively. Each `add_type` creates a subclass of the association class, defined on the parent class as `<Name>AssociationType<Type>`.

`Associations::Base` stores the parent class by name and resolves it with `Object.const_get` (so reloaded constants are picked up); a parent that was anonymous when the association was declared is kept by reference instead.

### Schema::Utils (`lib/schema/utils.rb`)

Utility methods for:
- `classify_name`: String → ClassName conversion
- `create_schema_class`: Dynamically creates nested schema classes
- `add_association_class`: Wires up association with proper modules
- `add_attribute_default_methods` / `add_association_default_methods`: Default value handling (`copy_default` hands each read a deep copy of the default)

### Error Handling

Two error storage mechanisms:

1. **Schema::Errors** (`lib/schema/errors.rb`): Simple hash-based storage, used standalone

2. **ActiveModel::Errors**: When `Schema::ActiveModelValidations` is included, `parsing_errors` returns `ActiveModel::Errors` instance

Parsing errors are distinct from validation errors:
- **Parsing errors**: Type conversion failures (string "abc" → integer)
- **Validation errors**: Business rule failures (via `validates` DSL)

`parsed!` raises `ParsingException` when there are parsing errors and `valid_model!` raises `ValidationException` when validations fail; `valid!` calls both. `valid?` runs validations only and does not look at parsing errors.

Parsing errors use these codes from `Schema::ParsingErrors`: `invalid`, `incompatible`, `unknown`, `unknown_attribute`, `unhandled_type`.

### CSV and Arrays

- **`Schema::ArrayHeaders`** (`lib/schema/array_headers.rb`): `map_headers_to_attributes(headers)` returns a nested hash of `{ field: { index: n } }` entries. Has-many fields are matched as `<prefix><n><key>` (prefix is the association name or an alias, `n` counts from 1) and map to `{ indexes: [...] }`. Has-one fields are matched by their own key or alias; a column already claimed by the parent or an earlier has-one isn't reused. Associations never map to a column of their own.
- **`Schema::Arrays`** (`lib/schema/arrays.rb`): `to_headers`, `to_empty_array`, `to_a` and `from_array(array, mapped_headers)`. Has-many associations need a `size:` option for the fixed-width methods.
- **`Schema::CSVParser`** (`lib/schema/csv_parser.rb`): wraps a `CSV` object, maps its header row once, and yields a model per row (`each`, `shift`, `missing_fields`).

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
