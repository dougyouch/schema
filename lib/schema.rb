# frozen_string_literal: true

# Schema is a series of tools for transforming data into models
module Schema
  autoload :ArrayHeaders, 'schema/array_headers'
  autoload :Arrays, 'schema/arrays'
  autoload :CSVParser, 'schema/csv_parser'
  autoload :Errors, 'schema/errors'
  autoload :CSVParser, 'schema/csv_parser'
  autoload :Model, 'schema/model'
  autoload :Utils, 'schema/utils'

  # Schema::Parsers are used to convert values into the correct data type
  module Parsers
    autoload :Array, 'schema/parsers/array'
    autoload :Common, 'schema/parsers/common'
    autoload :Hash, 'schema/parsers/hash'
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
