# frozen_string_literal: true

# SchemaValidator validates nested schemas: each one must have no parsing errors and pass its validations
class SchemaValidator < ActiveModel::EachValidator
  # Called by ActiveModel for `validates :x, schema: true`.
  # @api private
  def validate_each(record, attribute, value)
    record.errors.add(attribute, options.fetch(:message, :invalid)) unless valid_schema?(value)
  end

  private

  def valid_schema?(value)
    return true unless value

    schemas = value.is_a?(Array) ? value.compact : [value]
    # map before all? so every nested schema runs its validations and has its errors filled in
    schemas.map { |schema| parsed_and_valid?(schema) }.all?
  end

  def parsed_and_valid?(schema)
    valid = schema.valid?
    valid && schema.parsed?
  end
end
