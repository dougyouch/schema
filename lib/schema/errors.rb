module Schema
  class Errors
    attr_reader :errors

    def initialize
      @errors = {}
    end

    def [](name)
      @errors[name] || []
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
