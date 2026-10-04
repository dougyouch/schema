# frozen_string_literal: true

require 'spec_helper'

describe Schema::ParsingStatus do
  let(:model_class) do
    Class.new do
      include Schema::Model

      attribute :age, :integer
    end
  end

  context 'plain model' do
    it 'is parsed when there are no parsing errors' do
      model = model_class.from_hash(age: '3')
      expect(model.parsed?).to eq(true)
      expect { model.parsed! }.not_to raise_error
    end

    it 'raises with the failed attributes' do
      model = model_class.from_hash(age: 'x')
      expect(model.parsed?).to eq(false)
      expect { model.parsed! }.to raise_error(Schema::ParsingException, 'schema parsing failed for attributes age')
    end
  end
end
