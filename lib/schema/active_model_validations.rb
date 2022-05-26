# frozen_string_literal: true

require 'active_model'

module Schema
  # Schema::Model adds schema building methods to a class, uses ActiveModel::Errors for parsing_errors
  module ActiveModelValidations
    def self.included(base)
      base.schema_include ::ActiveModel::Validations
      base.schema_include OverrideParsingErrors
    end

    def valid_model!
      unless valid?
        raise ValidationException.new(
                "invalid values for attributes #{errors.map(&:attribute).join(', ')}",
                self,
                errors
              )
      end
    end

    def valid!
      parsed!
      valid_model!
    end

    # no-doc
    module OverrideParsingErrors
      def parsing_errors
        @parsing_errors ||= ActiveModel::Errors.new(self)
      end

      def parsed?
        parsing_errors.empty?
      end

      def parsed!
        unless parsed?
          raise ParsingException.new(
                  "schema parsing failed for attributes #{parsing_errors.errors.map(&:attribute).join(', ')}",
                  self,
                  parsing_errors
                )
        end
      end
    end
  end
end
