# frozen_string_literal: true

require 'active_model'

module Schema
  # One parsing error in {ActiveModelParsingErrors}: its type is the code (e.g. :invalid) and its
  # message is resolved when it's added. A plain ActiveModel::Error would resolve the message by
  # reading the attribute, which unknown keys and nested markers ("items:0") don't have.
  class ActiveModelParsingError < ActiveModel::Error
    # @return [String]
    def message
      options[:message]
    end
  end
end
