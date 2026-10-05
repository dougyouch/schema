# frozen_string_literal: true

require_relative 'lib/schema/version'

Gem::Specification.new do |s|
  s.name        = 'schema-model'
  s.version     = Schema::VERSION
  s.licenses    = ['MIT']
  s.summary     = 'Typed Ruby models built from hashes, JSON and CSV rows'
  s.description = 'Declare typed attributes and Schema turns incoming hashes, JSON and CSV rows into Ruby objects. ' \
                  'Values are coerced to integers, floats, booleans, dates, times, arrays and hashes, and bad input ' \
                  'is recorded as parsing errors instead of raised. Supports nested has_one/has_many associations, ' \
                  'polymorphic types chosen by a type field, CSV header mapping, and ActiveModel validations.'
  s.authors     = ['Doug Youch']
  s.email       = 'dougyouch@gmail.com'
  s.homepage    = 'https://github.com/dougyouch/schema'
  s.files       = Dir['lib/**/*.rb', 'bin/*', 'README.md', 'LICENSE.txt', 'CHANGELOG.md']
  s.required_ruby_version = '>= 3.3'
  s.bindir      = 'bin'
  s.executables = s.files.grep(%r{^bin/}) { |f| File.basename(f) }

  s.add_dependency 'inheritance-helper', '~> 0.2'
  s.metadata['rubygems_mfa_required'] = 'true'
  s.metadata['source_code_uri'] = 'https://github.com/dougyouch/schema'
  s.metadata['changelog_uri'] = 'https://github.com/dougyouch/schema/blob/master/CHANGELOG.md'
  s.metadata['bug_tracker_uri'] = 'https://github.com/dougyouch/schema/issues'
  s.metadata['documentation_uri'] = 'https://rubydoc.info/gems/schema-model'
end
