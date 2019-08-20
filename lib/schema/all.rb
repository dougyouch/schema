# frozen_string_literal: true

require 'inheritance-helper'

module Schema
  # Schema::All includes model, associations, parsers and active model validations
  module All
    def self.included(base)
      base.send(:include, ::Schema::Model)

      # associations
      base.schema_include ::Schema::Associations::HasOne
      base.schema_include ::Schema::Associations::HasMany

      # parsers
      base.schema_include ::Schema::Parsers::American
      base.schema_include ::Schema::Parsers::Array
      base.schema_include ::Schema::Parsers::Hash
      base.schema_include ::Schema::Parsers::Json

      # active model validations
      base.send(:include, ::Schema::ActiveModelValidations)
    end
  end
end
