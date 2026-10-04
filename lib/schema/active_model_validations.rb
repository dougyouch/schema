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

    # runs validations even when there are parsing errors, so full_error_messages has both
    def parsed_and_valid?
      valid = valid?
      valid && parsed?
    end

    # parsing error messages followed by the messages from the last validation run
    def full_error_messages
      parsing_errors.full_messages + errors.full_messages
    end

    # no-doc
    module OverrideParsingErrors
      def parsing_errors
        @parsing_errors ||= ActiveModelParsingErrors.new(self)
      end
    end
  end
end
