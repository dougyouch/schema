# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'schema-model'
  s.version     = '0.7.0'
  s.licenses    = ['MIT']
  s.summary     = 'Data transformation, validation, and type safety for Ruby'
  s.description = 'A flexible DSL for defining strongly-typed data models with automatic parsing, ' \
                  'nested associations, dynamic types, and ActiveModel validations'
  s.authors     = ['Doug Youch']
  s.email       = 'dougyouch@gmail.com'
  s.homepage    = 'https://github.com/dougyouch/schema'
  s.files       = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  s.bindir      = 'bin'
  s.executables = s.files.grep(%r{^bin/}) { |f| File.basename(f) }

  s.add_dependency 'inheritance-helper'
  s.metadata['rubygems_mfa_required'] = 'true'
end
