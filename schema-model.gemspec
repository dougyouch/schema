# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'schema-model'
  s.version     = '0.6.0'
  s.licenses    = ['MIT']
  s.summary     = 'Schema Model'
  s.description = 'Easy way to create models from payloads'
  s.authors     = ['Doug Youch']
  s.email       = 'dougyouch@gmail.com'
  s.homepage    = 'https://github.com/dougyouch/schema'
  s.files       = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  s.bindir      = 'bin'
  s.executables = s.files.grep(%r{^bin/}) { |f| File.basename(f) }

  s.add_runtime_dependency 'inheritance-helper'
end
