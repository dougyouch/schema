# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Test Commands

```bash
# Install dependencies
bundle install

# Run all tests
bundle exec rspec

# Run a single test file
bundle exec rspec spec/schema/model_spec.rb

# Run a specific test by line number
bundle exec rspec spec/schema/model_spec.rb:42

# Run linter
bundle exec rubocop

# Auto-fix linter issues
bundle exec rubocop -A
```

## Architecture

This is a Ruby gem (`schema-model`) for data transformation, validation, and type safety. It transforms hash data into strongly-typed model objects.

### Core Module Structure

- **Schema::Model** (`lib/schema/model.rb`) - Foundation module providing `attribute` definitions, `from_hash` class method, and attribute accessors.

- **Schema::All** (`lib/schema/all.rb`) - Convenience module bundling Model + Associations + Parsers + ActiveModel validations. This is the typical include.

- **Schema::Parsers** - Type parsers in `lib/schema/parsers/`:
  - `Common` - integer, string, float, time, date, boolean
  - `American` - american_date, american_time (MM/DD/YYYY format)
  - `Array` - array with optional separator and data_type
  - `Hash` - hash/dictionary values
  - `Json` - JSON string parsing

- **Schema::Associations** - `HasOne` and `HasMany` for nested relationships. `DynamicTypes` enables polymorphic associations via `type_field`/`add_type`.

- **Schema::Arrays** (`lib/schema/arrays.rb`) - Convert models to/from flat arrays for CSV support.

- **Schema::ArrayHeaders** (`lib/schema/array_headers.rb`) - Map CSV headers to schema attributes.

### Key Patterns

**Attribute Definition**: Each `attribute` call generates getter, setter, and `<name>_was_set?` predicate. Setter invokes type-specific parser.

**Parsing Errors**: Stored in `parsing_errors`. Parsers add errors for invalid values rather than raising exceptions. With ActiveModelValidations, use `parsed?`/`parsed!`.

**Schema Inheritance**: Uses `inheritance-helper` gem. Schema definitions accumulate via `add_value_to_class_method(:schema, ...)`.

**Dynamic Types**: For polymorphic associations, use `type_field` option with `add_type` blocks. Supports `external_type_field`, `type_ignorecase`, and `default_type`.

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
