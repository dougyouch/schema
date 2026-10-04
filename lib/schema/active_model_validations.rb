# frozen_string_literal: true

require 'active_model'

module Schema
  # Schema::ActiveModelValidations adds ActiveModel validations, and readable ActiveModel::Errors for parsing_errors
  module ActiveModelValidations
    def self.included(base)
      base.schema_include ::ActiveModel::Validations
      base.schema_include OverrideParsingErrors
    end

    def valid_model!
      return if valid?

      raise ValidationException.new(
        "invalid values for attributes #{errors.map(&:attribute).join(', ')}",
        self,
        errors
      )
    end

    def valid!
      parsed!
      valid_model!
    end

    # no-doc
    module OverrideParsingErrors
      def parsing_errors
        @parsing_errors ||= ActiveModelParsingErrors.new(self)
      end
    end
  end
end
