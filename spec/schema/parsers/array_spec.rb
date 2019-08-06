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

    describe 'string value' do
      let(:costs) { '1,4,2,6' }
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

      describe 'separator option' do
        before(:each) do
          schema_options = model_class.schema[:costs].dup
          schema_options[:separator] = ','
          schema_options[:data_type] = :integer
          model_class.add_value_to_class_method(:schema, costs: schema_options)
        end

        it 'returns costs' do
          expect(subject.costs).to eq([1, 4, 2, 6])
        end

        describe 'invalid values' do
          let(:costs) { 'invalid,4,,6' }

          it 'returns costs' do
            expect(subject.costs).to eq([nil, 4, nil, 6])
          end

          it 'has parsing_errors' do
            expect(subject.parsing_errors['costs:0']).to eq([:invalid])
            expect(subject.parsing_errors['costs:2']).to eq([:invalid])
          end
        end
      end
    end
  end
end
