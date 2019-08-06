require 'spec_helper'

describe Schema::Parsers::Array do
  let(:model_class_name) { 'ModelClass' + SecureRandom.hex(10) }
  let(:model_class) do
    kls = Class.new do
      include Schema::Model
      include Schema::Parsers::Array

      attribute :id, :integer, alias: :identifier
      attribute :name, :string
      attribute :costs, :array
    end
    Object.const_set(model_class_name, kls)
    Object.const_get(model_class_name)
  end

  context 'parse_array' do
    describe 'valid payload' do
      let(:costs) { [1, 4, 2, 6] }
      let(:payload) do
        {
          id: rand(1_000_000),
          name: 'Name ' + SecureRandom.hex(8),
          costs: costs
        }
      end

      subject { model_class.from_hash(payload) }

      it 'set the array attribute' do
        expect(subject.costs).to eq(costs)
      end
    end

    describe 'invalid payload' do
      let(:costs) { 90.1 }
      let(:payload) do
        {
          id: rand(1_000_000),
          name: 'Name ' + SecureRandom.hex(8),
          costs: costs
        }
      end

      subject { model_class.from_hash(payload) }

      it 'returns nil' do
        expect(subject.costs).to eq(nil)
      end

      it 'parsing_errors contains incompatable' do
        expect(subject.parsing_errors[:costs]).to eq([:incompatable])
      end
    end
  end
end
