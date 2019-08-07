# frozen_string_literal: true

# SchemaValidator validates nested schemas
class SchemaValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add(attribute, options.fetch(:message, :invalid)) unless valid_schema?(value)
  end

  private

  def valid_schema?(value)
    return true unless value

    value.is_a?(Array) ? value.all?(:valid?) : value.valid?
  end
end
