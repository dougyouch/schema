# frozen_string_literal: true

# SchemaValidator validates nested schemas
class SchemaValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add(attribute, options.fetch(:message, :invalid)) if value && !value.valid?
  end
end
