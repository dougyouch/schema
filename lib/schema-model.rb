# frozen_string_literal: true

autoload :SchemaValidator, 'schema_validator'

# Schema is a series of tools for transforming data into models
module Schema
  # Base error for parsed! and valid_model!; carries the model and its errors.
  class SchemaException < StandardError
    attr_reader :schema,
                :errors

    def initialize(msg, schema, errors)
      super(msg)
      @schema = schema
      @errors = errors
    end
  end

  # Raised by parsed! (and valid!) when the model has parsing errors.
  class ParsingException < SchemaException; end
  # Raised by valid_model! (and valid!) when the model fails its validations.
  class ValidationException < SchemaException; end

  # raised when a value is assigned to an attribute whose type has no parse_<type> method
  class UnknownTypeError < StandardError; end

  autoload :ActiveModelValidations, 'schema/active_model_validations'
  autoload :All, 'schema/all'
  autoload :ActiveModelParsingError, 'schema/active_model_parsing_error'
  autoload :ActiveModelParsingErrors, 'schema/active_model_parsing_errors'
  autoload :ArrayHeaders, 'schema/array_headers'
  autoload :Arrays, 'schema/arrays'
  autoload :AttributeValues, 'schema/attribute_values'
  autoload :CSVParser, 'schema/csv_parser'
  autoload :DeepCopy, 'schema/deep_copy'
  autoload :Errors, 'schema/errors'
  autoload :Model, 'schema/model'
  autoload :ParsingErrors, 'schema/parsing_errors'
  autoload :ParsingStatus, 'schema/parsing_status'
  autoload :Utils, 'schema/utils'

  # Schema::Parsers are used to convert values into the correct data type
  module Parsers
    autoload :American, 'schema/parsers/american'
    autoload :Array, 'schema/parsers/array'
    autoload :Common, 'schema/parsers/common'
    autoload :Decimal, 'schema/parsers/decimal'
    autoload :Hash, 'schema/parsers/hash'
    autoload :Json, 'schema/parsers/json'
    autoload :StringValue, 'schema/parsers/string_value'
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
