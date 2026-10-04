# frozen_string_literal: true

module Schema
  # Schema::ParsingErrors is a collection of parsing error messages
  module ParsingErrors
    # The value couldn't be parsed.
    INVALID = 'invalid'
    # The value is the wrong kind, e.g. a hash for a string attribute.
    INCOMPATIBLE = 'incompatible'
    # No dynamic type matched the type field.
    UNKNOWN = 'unknown'
    # The key isn't in the schema.
    UNKNOWN_ATTRIBUTE = 'unknown_attribute'
    # The parser doesn't handle the value's class.
    UNHANDLED_TYPE = 'unhandled_type'
  end
end
