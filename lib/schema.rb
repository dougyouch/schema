module Schema
  autoload :Model, 'schema/model'

  module Parsers
    autoload :Common, 'schema/parsers/common'
  end

  module Relation
    autoload :HasOne, 'schema/relation/has_one'
  end
end
