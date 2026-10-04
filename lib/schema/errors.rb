# frozen_string_literal: true

module Schema
  # Schema::Errors used internally for testing mainly, recommend using ActiveModel::Validations
  class Errors
    attr_reader :errors

    # Returned by {#[]} for names without errors.
    EMPTY_ARRAY = [].freeze

    def initialize
      @errors = {}
    end

    # @param name [Symbol, String]
    # @return [Array<String>] error codes for name (empty when none)
    def [](name)
      @errors[name] || EMPTY_ARRAY
    end

    # Records an error code for name.
    # @param name [Symbol, String]
    # @param error [String] a {Schema::ParsingErrors} code
    # @return [Array<String>]
    def add(name, error)
      @errors[name] ||= []
      @errors[name] << error
    end
    alias []= add

    def empty?
      @errors.empty?
    end

    # @return [Array] names that have errors
    def attribute_names
      @errors.keys
    end
  end
end
