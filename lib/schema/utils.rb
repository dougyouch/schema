module Schema
  module Utils
    extend self

    def classify_name(base, name)
      base + name.gsub(/[^\da-z_-]/, '').gsub(/(^.|[_|-].)/) { |m| m[-1].upcase }
    end
  end
end
