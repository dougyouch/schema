# frozen_string_literal: true

require 'active_model'

module Schema
  # Schema::Model adds schema building methods to a class, uses ActiveModel::Errors for parsing_errors
  module ActiveModelValidations
    def self.included(base)
      base.schema_include ::ActiveModel::Validations
      base.schema_include OverrideParsingErrors
    end

    # no-doc
    module OverrideParsingErrors
      def parsing_errors
        @parsing_errors ||= ActiveModel::Errors.new(self)
      end
    end
  end
end
