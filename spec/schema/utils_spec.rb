# frozen_string_literal: true

require 'spec_helper'

describe Schema::Utils do
  context 'classify_name' do
    let(:name) { 'name-foo_bar_1!' }

    subject { Schema::Utils.classify_name(name) }

    it 'converts the name to a class name' do
      expect(subject).to eq('NameFooBar1')
    end
  end
end
