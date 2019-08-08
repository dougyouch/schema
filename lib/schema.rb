# frozen_string_literal: true

autoload :SchemaValidator, 'schema_validator'

# Schema is a series of tools for transforming data into models
module Schema
  autoload :ActiveModelValidations, 'schema/active_model_validations'
  autoload :ArrayHeaders, 'schema/array_headers'
  autoload :Arrays, 'schema/arrays'
  autoload :CSVParser, 'schema/csv_parser'
  autoload :Errors, 'schema/errors'
  autoload :CSVParser, 'schema/csv_parser'
  autoload :Model, 'schema/model'
  autoload :ParsingErrors, 'schema/parsing_errors'
  autoload :Utils, 'schema/utils'

  # Schema::Parsers are used to convert values into the correct data type
  module Parsers
    autoload :American, 'schema/parsers/american'
    autoload :Array, 'schema/parsers/array'
    autoload :Common, 'schema/parsers/common'
    autoload :Hash, 'schema/parsers/hash'
    autoload :Json, 'schema/parsers/json'
  end

  # Schema::Associations mange the associations between schema models
  module Associations
    autoload :Base, 'schema/associations/base'
    autoload :DynamicTypes, 'schema/associations/dynamic_types'
    autoload :HasMany, 'schema/associations/has_many'
    autoload :HasOne, 'schema/associations/has_one'
    autoload :SchemaCreator, 'schema/associations/schema_creator'
  end
end
