require 'spec_helper'

describe Schema::Parsers::Common do
  let(:model_class_name) { 'ModelClass' + SecureRandom.hex(10) }
  let(:model_class) do
    kls = Struct.new(
      :id,
      :name,
      :cost
    ) do
      include ActiveModel::Validations
      include Schema::Parsers::Common
    end
    Object.const_set(model_class_name, kls)
    Object.const_get(model_class_name)
  end
  let(:model_id) { rand(1_000_000) }
  let(:model_name) { SecureRandom.uuid }
  let(:model_cost) { rand(100).to_f + rand }
  let(:model) { model_class.new(model_id, model_name, model_cost) }
  let(:parsing_errors) { model.errors }
  let(:has_parsing_errors) { ! parsing_errors.empty? }

  context 'parse_integer' do
    let(:field_name) { :id }
    let(:value) { model_id }
    subject { model.parse_integer(field_name, parsing_errors, value) }

    describe 'integer value' do
      let(:value) { rand(1_000_000) }

      it 'has no errors' do
        expect(subject).to eq(value)
        expect(has_parsing_errors).to eq(false)
        expect(subject.object_id).to eq(value.object_id)
      end
    end

    describe 'string value' do
      let(:value) { rand(1_000_000).to_s }

      it 'has no errors' do
        expect(subject).to eq(value.to_i)
        expect(has_parsing_errors).to eq(false)
      end

      describe 'not a number' do
        let(:value) { 'not_a_number' }

        it 'has errors' do
          expect(subject).to eq(nil)
          expect(has_parsing_errors).to eq(true)
        end
      end

      describe 'number string starting with 0' do
        let(:value) { '0' + rand(1_000_000).to_s }

        it 'has errors' do
          expect(subject).to eq(nil)
          expect(has_parsing_errors).to eq(true)
        end
      end
    end

    describe 'float value' do
      let(:value) { rand(1_000_000).to_f }

      it 'has no errors' do
        expect(subject).to eq(value.to_i)
        expect(has_parsing_errors).to eq(false)
      end

      describe 'with decimal points' do
        let(:value) { rand(1_000_000).to_f + 0.1 }

        it 'has errors' do
          expect(subject).to eq(value.to_i)
          expect(has_parsing_errors).to eq(true)
        end
      end

      describe 'none integer types' do
        let(:value) { {id: 4} }

        it 'has errors' do
          expect(subject).to eq(nil)
          expect(has_parsing_errors).to eq(true)
        end
      end
    end

    describe 'invalid type' do
      let(:value) { {a: 1} }

      it 'has errors' do
        expect(subject).to eq(nil)
        expect(has_parsing_errors).to eq(true)
      end
    end
  end

  context 'parse_string' do
    let(:field_name) { :name }
    let(:value) { model_name }
    subject { model.parse_string(field_name, parsing_errors, value) }

    describe 'string value' do
      it 'has no errors' do
        expect(subject).to eq(model_name)
        expect(subject.object_id).to eq(model_name.object_id)
        expect(has_parsing_errors).to eq(false)
      end
    end

    describe 'numeric value' do
      let(:value) { rand(1_000_000) }

      it 'has no errors' do
        expect(subject).to eq(value.to_s)
        expect(has_parsing_errors).to eq(false)
      end
    end

    describe 'hash value' do
      let(:value) { {a: 1} }

      it 'has errors' do
        expect(subject).to eq(nil)
        expect(has_parsing_errors).to eq(true)
      end
    end

    describe 'array value' do
      let(:value) { [1] }

      it 'has errors' do
        expect(subject).to eq(nil)
        expect(has_parsing_errors).to eq(true)
      end
    end
  end

  context 'parse_number' do
    let(:field_name) { :cost }
    let(:value) { model_cost }
    subject { model.parse_number(field_name, parsing_errors, value) }

    describe 'float value' do
      it 'has no errors' do
        expect(subject).to eq(value)
        expect(has_parsing_errors).to eq(false)
        expect(subject.object_id).to eq(value.object_id)
      end
    end

    describe 'string value' do
      let(:value) { (rand(1_000_000) + rand).to_s }

      it 'has no errors' do
        expect(subject).to eq(value.to_f)
        expect(has_parsing_errors).to eq(false)
      end

      describe 'not a number' do
        let(:value) { 'not_a_number' }

        it 'has errors' do
          expect(subject).to eq(nil)
          expect(has_parsing_errors).to eq(true)
        end
      end

      describe 'number string starting with 0' do
        let(:value) { '0' + rand(1_000_000).to_s }

        it 'has errors' do
          expect(subject).to eq(nil)
          expect(has_parsing_errors).to eq(true)
        end
      end
    end

    describe 'integer value' do
      let(:value) { rand(1_000_000) }

      it 'has no errors' do
        expect(subject).to eq(value.to_i)
        expect(has_parsing_errors).to eq(false)
      end
    end

    describe 'invalid type' do
      let(:value) { {a: 1} }

      it 'has errors' do
        expect(subject).to eq(nil)
        expect(has_parsing_errors).to eq(true)
      end
    end
  end
end
