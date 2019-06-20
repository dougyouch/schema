module Schema
  class Errors
    attr_reader :errors

    def initialize
      @errors = {}
    end

    def add(name, error)
      @errors[name] ||= []
      @errors[name] << error
    end

    def empty?
      @errors.empty?
    end
  end
end
