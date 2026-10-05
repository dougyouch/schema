# frozen_string_literal: true

require 'active_model'

module Schema
  # Schema::ActiveModelParsingErrors gives parsing errors readable messages, e.g. "Age is invalid"
  # instead of "Age invalid", while keeping the code as the error's type, so
  # `parsing_errors.details` reports `{ error: :invalid }`. Override messages with I18n keys under
  # schema.parsing_errors, and register more codes with {.add_message}.
  class ActiveModelParsingErrors < ActiveModel::Errors
    # Default English message for each built-in parsing error code.
    MESSAGES = {
      ::Schema::ParsingErrors::INVALID => 'is invalid',
      ::Schema::ParsingErrors::INCOMPATIBLE => 'is an incompatible type',
      ::Schema::ParsingErrors::UNKNOWN => 'has an unknown type',
      ::Schema::ParsingErrors::UNKNOWN_ATTRIBUTE => 'is an unknown attribute',
      ::Schema::ParsingErrors::UNHANDLED_TYPE => 'is an unhandled type'
    }.freeze

    # @return [Hash{String => String}] every known code and its default message
    def self.messages
      @messages ||= MESSAGES.dup
    end

    # Registers a parsing error code, e.g. for a custom parser.
    # @example
    #   Schema::ActiveModelParsingErrors.add_message(:read_only, 'is read only')
    #   model.parsing_errors.add(:id, :read_only) # => "Id is read only", details { error: :read_only }
    # @param code [Symbol, String]
    # @param message [String] default message; an I18n key schema.parsing_errors.<code> overrides it
    # @return [void]
    def self.add_message(code, message)
      messages[code.to_s] = message
    end

    # Known codes are stored as the error's type with a readable message. Anything else is kept
    # as a message string, since parsing error keys (e.g. "items:0") often aren't model attributes.
    def add(attribute, type = :invalid, **)
      code = type.to_s
      return super unless self.class.messages.key?(code)

      error = ActiveModelParsingError.new(@base, attribute, code.to_sym, message: message_for(code))
      @errors.append(error)
      error
    end

    private

    def message_for(code)
      I18n.t("schema.parsing_errors.#{code}", default: self.class.messages[code])
    end
  end
end
