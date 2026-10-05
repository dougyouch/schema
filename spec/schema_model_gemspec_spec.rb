# frozen_string_literal: true

require 'spec_helper'

describe 'schema-model.gemspec' do
  let(:spec) { Gem::Specification.load(File.expand_path('../schema-model.gemspec', __dir__)) }

  it 'packages only the library, executable and user-facing docs' do
    expect(spec.files.reject { |file| file.start_with?('lib/', 'bin/') }).to contain_exactly(
      'CHANGELOG.md', 'LICENSE.txt', 'README.md'
    )
  end

  it 'limits inheritance-helper to compatible versions' do
    dependency = spec.runtime_dependencies.find { |dep| dep.name == 'inheritance-helper' }
    expect(dependency.requirement).to be_satisfied_by(Gem::Version.new('0.2.6'))
    expect(dependency.requirement).to be_satisfied_by(Gem::Version.new('1.9.0'))
    expect(dependency.requirement).not_to be_satisfied_by(Gem::Version.new('2.0.0'))
  end

  it 'links to the source, changelog, issues and api docs' do
    expect(spec.metadata).to include(
      'source_code_uri' => 'https://github.com/dougyouch/schema',
      'changelog_uri' => 'https://github.com/dougyouch/schema/blob/master/CHANGELOG.md',
      'bug_tracker_uri' => 'https://github.com/dougyouch/schema/issues',
      'documentation_uri' => 'https://rubydoc.info/gems/schema-model'
    )
  end
end
