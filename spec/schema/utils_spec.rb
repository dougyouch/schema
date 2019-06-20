require 'spec_helper'

describe Schema::Utils do
  context 'classify_name' do
    let(:base) { 'SchemaUtilsTest' }
    let(:name) { 'name-foo_bar_1!' }

    subject { Schema::Utils.classify_name(base, name) }

    it 'converts the name to a class name' do
      expect(subject).to eq('SchemaUtilsTestNameFooBar1')
    end
  end
end
