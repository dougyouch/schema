module Schema
  autoload :ArrayHeaders, 'schema/array_headers'
  autoload :Arrays, 'schema/arrays'
  autoload :CSVParser, 'schema/csv_parser'
  autoload :Errors, 'schema/errors'
  autoload :Model, 'schema/model'
  autoload :Utils, 'schema/utils'

  module Parsers
    autoload :Common, 'schema/parsers/common'
  end

  module Relation
    autoload :HasMany, 'schema/relation/has_many'
    autoload :HasOne, 'schema/relation/has_one'
  end
end
