module Schema
  autoload :Errors, 'schema/errors'
  autoload :Model, 'schema/model'
  autoload :Utils, 'schema/utils'

  module Parsers
    autoload :Common, 'schema/parsers/common'
  end

  module Relation
    autoload :HasOne, 'schema/relation/has_one'
  end
end
