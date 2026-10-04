# frozen_string_literal: true

require 'spec_helper'

describe 'schema-model.gemspec' do
  let(:spec) { Gem::Specification.load(File.expand_path('../schema-model.gemspec', __dir__)) }

  it 'packages only the library, executable and user-facing docs' do
    expect(spec.files.reject { |file| file.start_with?('lib/', 'bin/') }).to contain_exactly(
      'CHANGELOG.md', 'LICENSE.txt', 'README.md'
    )
  end

  it 'links to the source, changelog and issues' do
    expect(spec.metadata).to include(
      'source_code_uri' => 'https://github.com/dougyouch/schema',
      'changelog_uri' => 'https://github.com/dougyouch/schema/blob/master/CHANGELOG.md',
      'bug_tracker_uri' => 'https://github.com/dougyouch/schema/issues'
    )
  end
end
