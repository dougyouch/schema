# frozen_string_literal: true

module Schema
  # Schema::ParsingStatus reports whether a model parsed cleanly, and raises at an explicit boundary
  module ParsingStatus
    def parsed?
      parsing_errors.empty?
    end

    def parsed!
      return if parsed?

      raise ParsingException.new(
        "schema parsing failed for attributes #{parsing_errors.attribute_names.join(', ')}",
        self,
        parsing_errors
      )
    end
  end
end
