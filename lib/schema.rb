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
    autoload :Common, 'schema/parsers/common'
  end

  # Schema::Relation mange the associations between schema models
  module Relation
    autoload :HasMany, 'schema/relation/has_many'
    autoload :HasOne, 'schema/relation/has_one'
  end
end
