# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Test Commands

```bash
# Install dependencies
bundle install

# Run all tests
bundle exec rake spec

# Run a single test file
bundle exec rspec spec/schema/model_spec.rb

# Run a specific test by line number
bundle exec rspec spec/schema/model_spec.rb:42
```

## Architecture

This is a Ruby gem (`schema-model`) for data transformation, validation, and type safety. It transforms hash data into strongly-typed model objects.

### Core Module Structure

- **Schema::Model** (`lib/schema/model.rb`) - The foundation module that provides `attribute` definitions, `from_hash` class method, and attribute accessors. Includes `update_attributes` for populating models from data.

- **Schema::All** (`lib/schema/all.rb`) - Convenience module that bundles Model + all Associations + all Parsers + ActiveModel validations. This is the typical include for schema classes.

- **Schema::Parsers::Common** (`lib/schema/parsers/common.rb`) - Base parsers for fundamental types: `parse_integer`, `parse_string`, `parse_float`, `parse_time`, `parse_date`, `parse_boolean`. Additional parsers in `Parsers::American`, `Parsers::Array`, `Parsers::Hash`, `Parsers::Json`.

- **Schema::Associations** - `HasOne` and `HasMany` modules for nested schema relationships. `DynamicTypes` enables polymorphic associations via `type_field` and `add_type`.

### Key Patterns

**Attribute Definition**: Each `attribute` call generates a getter, setter, and `<name>_was_set?` predicate. The setter automatically invokes the type-specific parser (e.g., `parse_integer`).

**Parsing Errors**: Stored in `parsing_errors` (a `Schema::Errors` instance). Parsers add errors for invalid/incompatible values rather than raising exceptions.

**Schema Inheritance**: Uses `inheritance-helper` gem. Schema definitions accumulate via `add_value_to_class_method(:schema, ...)`.

**Dynamic Types**: For polymorphic has_many associations, use `type_field` option with `add_type` blocks to define type-specific attributes.

## Code Commits

Format using angular formatting:
```
<type>(<scope>): <short summary>
```
- **type**: build|ci|docs|feat|fix|perf|refactor|test
- **scope**: The feature or component of the service we're working on
- **summary**: Summary in present tense. Not capitalized. No period at the end.

## Documentation Maintenance

When modifying the codebase, keep documentation in sync:
- **ARCHITECTURE.md** - Update when adding/removing classes, changing component relationships, or altering data flow patterns
- **README.md** - Update when adding new features, changing public APIs, or modifying usage examples
- **Code comments** - Update inline documentation when changing method signatures or behavior
