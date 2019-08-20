# frozen_string_literal: true

source 'http://rubygems.org'

gem 'inheritance-helper'

group :development do
  activemodel_version =
    case ENV['RUBY_VERSION']
    when /1\.9\.3/
      3
    when /2\.1\.9/
      4
    else
      5
    end
  gem 'activemodel', "~> #{activemodel_version}"
  gem 'rake'
  gem 'rubocop'
end

group :spec do
  gem 'rspec'
  gem 'simplecov'
end
