# frozen_string_literal: true

require 'spec_helper'

describe 'association _was_set? predicates' do
  let(:model_class) do
    Class.new do
      include Schema::All

      has_one(:profile, default: true) { attribute :bio, :string }
      has_many(:items, default: true) { attribute :qty, :integer }
    end
  end

  it 'is true when the input had the key, null included' do
    model = model_class.from_hash(profile: nil, items: [{ qty: 1 }])

    expect(model.profile_was_set?).to be(true)
    expect(model.items_was_set?).to be(true)
  end

  it 'is false when the key was left out, even after reading a default' do
    model = model_class.from_hash({})
    model.profile
    model.items

    expect(model.profile_was_set?).to be(false)
    expect(model.items_was_set?).to be(false)
  end
end
