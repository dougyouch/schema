# frozen_string_literal: true

require 'active_model'

module Schema
  # Schema::ActiveModelParsingErrors turns parsing error codes into readable messages,
  # e.g. "Age is invalid" instead of "Age invalid". Override them with I18n keys under schema.parsing_errors.
  class ActiveModelParsingErrors < ActiveModel::Errors
    # Default English message for each parsing error code.
    MESSAGES = {
      ::Schema::ParsingErrors::INVALID => 'is invalid',
      ::Schema::ParsingErrors::INCOMPATIBLE => 'is an incompatible type',
      ::Schema::ParsingErrors::UNKNOWN => 'has an unknown type',
      ::Schema::ParsingErrors::UNKNOWN_ATTRIBUTE => 'is an unknown attribute',
      ::Schema::ParsingErrors::UNHANDLED_TYPE => 'is an unhandled type'
    }.freeze

    # parsing error keys (e.g. "items:0" or an unknown key) often aren't attributes on the model,
    # so codes are added as message strings rather than ActiveModel error types
    def add(attribute, type = :invalid, **)
      super(attribute, message_for(type), **)
    end

    private

    def message_for(type)
      return type unless MESSAGES.key?(type)

      I18n.t("schema.parsing_errors.#{type}", default: MESSAGES[type])
    end
  end
end
