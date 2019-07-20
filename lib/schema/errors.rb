# frozen_string_literal: true

module Schema
  class Errors
    attr_reader :errors

    EMPTY_ARRAY = [].freeze

    def initialize
      @errors = {}
    end

    def [](name)
      @errors[name] || EMPTY_ARRAY
    end

    def add(name, error)
      @errors[name] ||= []
      @errors[name] << error
    end
    alias []= add

    def empty?
      @errors.empty?
    end
  end
end
