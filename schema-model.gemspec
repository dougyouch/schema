# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'schema-model'
  s.version     = '0.4.7'
  s.licenses    = ['MIT']
  s.summary     = 'Schema Model'
  s.description = 'Easy way to create models from payloads'
  s.authors     = ['Doug Youch']
  s.email       = 'dougyouch@gmail.com'
  s.homepage    = 'https://github.com/dougyouch/schema'
  s.files       = Dir.glob('lib/**/*.rb')

  s.add_runtime_dependency 'inheritance-helper'
end
