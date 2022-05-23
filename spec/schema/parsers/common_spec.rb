require 'spec_helper'

describe Schema::Parsers::Common do
  let(:model_class_name) { 'ModelClass' + SecureRandom.hex(10) }
  let(:model_class) do
    kls = Struct.new(
      :id,
      :name,
      :cost,
      :time,
      :date,
      :active
    ) do
      include Schema::Parsers::Common

      def parsing_errors
        @parsing_errors ||= ::Schema::Errors.new
      end
    end
    Object.const_set(model_class_name, kls)
    Object.const_get(model_class_name)
  end
  let(:model_id) { rand(1_000_000) }
  let(:model_name) { SecureRandom.uuid }
  let(:model_cost) { rand(100).to_f + rand }
  let(:model_time) { Time.now }
  let(:model_date) { model_time.to_date }
  let(:model_active) { true }
  let(:model) { model_class.new(model_id, model_name, model_cost, model_time, model_date, model_active) }
  let(:parsing_errors) { model.parsing_errors }
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

      describe 'zero' do
        let(:value) { '0' }

        it 'has no errors' do
          expect(subject).to eq(0)
          expect(has_parsing_errors).to eq(false)
        end
      end

      describe 'not a float' do
        let(:value) { 'not_a_float' }

        it 'has errors' do
          expect(subject).to eq(nil)
          expect(has_parsing_errors).to eq(true)
        end
      end

      describe 'float string starting with 0' do
        let(:value) { '0' + rand(1_000_000).to_s }

        it 'has errors' do
          expect(subject).to eq(nil)
          expect(has_parsing_errors).to eq(true)
        end
      end

      describe 'float value with a .0' do
        let(:value) { '19191.0' }

        it 'has no errors' do
          expect(subject).to eq(value.to_i)
          expect(has_parsing_errors).to eq(false)
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

    describe 'nil value' do
      let(:value) { nil }

      it 'has no errors' do
        expect(subject).to eq(nil)
        expect(has_parsing_errors).to eq(false)
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

    describe 'nil value' do
      let(:value) { nil }

      it 'has no errors' do
        expect(subject).to eq(nil)
        expect(has_parsing_errors).to eq(false)
      end
    end
  end

  context 'parse_float' do
    let(:field_name) { :cost }
    let(:value) { model_cost }
    subject { model.parse_float(field_name, parsing_errors, value) }

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

      describe 'zero' do
        let(:value) { '0' }

        it 'has no errors' do
          expect(subject).to eq(0)
          expect(has_parsing_errors).to eq(false)
        end
      end

      describe 'starts with zero' do
        let(:value) { rand.to_s }

        it 'has no errors' do
          expect(subject).to eq(value.to_f)
          expect(has_parsing_errors).to eq(false)
        end
      end

      describe 'not a float' do
        let(:value) { 'not_a_float' }

        it 'has errors' do
          expect(subject).to eq(nil)
          expect(has_parsing_errors).to eq(true)
        end
      end

      describe 'float string starting with 0' do
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

    describe 'nil value' do
      let(:value) { nil }

      it 'has no errors' do
        expect(subject).to eq(nil)
        expect(has_parsing_errors).to eq(false)
      end
    end
  end

  context 'parse_time' do
    let(:field_name) { :time }
    let(:value) { model_time }
    subject { model.parse_time(field_name, parsing_errors, value) }

    describe 'time value' do
      it 'has no errors' do
        expect(subject).to eq(value)
        expect(subject.object_id).to eq(value.object_id)
        expect(has_parsing_errors).to eq(false)
      end
    end

    describe 'date value' do
      let(:value) { Time.now.to_date }

      it 'has no errors' do
        expect(subject).to eq(value.to_date.to_time)
        expect(has_parsing_errors).to eq(false)
      end
    end

    describe 'string value' do
      let(:time) { Time.xmlschema(Time.now.xmlschema) }
      let(:value) { time.xmlschema }

      it 'has no errors' do
        expect(subject).to eq(time)
        expect(has_parsing_errors).to eq(false)
      end

      describe 'invalid time format' do
        let(:value) { time.strftime('%Y-%m-%d %H:%M:%S') }

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

    describe 'nil value' do
      let(:value) { nil }

      it 'has no errors' do
        expect(subject).to eq(nil)
        expect(has_parsing_errors).to eq(false)
      end
    end
  end

  context 'parse_date' do
    let(:field_name) { :date }
    let(:value) { model_date }
    subject { model.parse_date(field_name, parsing_errors, value) }

    describe 'date value' do
      it 'has no errors' do
        expect(subject).to eq(value)
        expect(subject.object_id).to eq(value.object_id)
        expect(has_parsing_errors).to eq(false)
      end
    end

    describe 'time value' do
      let(:value) { Time.now }

      it 'has no errors' do
        expect(subject).to eq(value.to_date)
        expect(has_parsing_errors).to eq(false)
      end
    end

    describe 'string value' do
      let(:time) { Time.new(2020, 1, 20) }
      let(:date) { time.to_date }
      let(:value) { date.to_s }

      it 'has no errors' do
        expect(subject).to eq(date)
        expect(has_parsing_errors).to eq(false)
      end

      describe 'invalid time format' do
        let(:value) { time.strftime('%m/%d/%Y') }

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

    describe 'nil value' do
      let(:value) { nil }

      it 'has no errors' do
        expect(subject).to eq(nil)
        expect(has_parsing_errors).to eq(false)
      end
    end
  end

  context 'parse_boolean' do
    let(:field_name) { :active }
    let(:value) { model_active }
    subject { model.parse_boolean(field_name, parsing_errors, value) }

    describe 'true value' do
      let(:value) { true }

      it 'has no errors' do
        expect(subject).to eq(true)
        expect(has_parsing_errors).to eq(false)
      end
    end

    describe 'false value' do
      let(:value) { false }

      it 'has no errors' do
        expect(subject).to eq(false)
        expect(has_parsing_errors).to eq(false)
      end
    end

    describe 'integer value' do
      let(:value) { rand(1_000_000) + 1 }

      it 'has no errors' do
        expect(subject).to eq(true)
        expect(has_parsing_errors).to eq(false)
      end

      describe 'zero' do
        let(:value) { 0 }

        it 'has no errors' do
          expect(subject).to eq(false)
          expect(has_parsing_errors).to eq(false)
        end
      end
    end

    describe 'float value' do
      let(:value) { (rand(1_000_000) + 1).to_f + rand}

      it 'has no errors' do
        expect(subject).to eq(true)
        expect(has_parsing_errors).to eq(false)
      end

      describe 'zero' do
        let(:value) { 0.0 }

        it 'has no errors' do
          expect(subject).to eq(false)
          expect(has_parsing_errors).to eq(false)
        end
      end
    end

    describe 'string value' do
      describe 'truthy values' do
        let(:truthy_examples) do
          [
            'T',
            'True',
            'y',
            'yEs',
            '1',
            'ON'
          ]
        end

        it 'truthy values are true' do
          expect(truthy_examples.all? { |value| model.parse_boolean(field_name, parsing_errors, value) }).to eq(true)
          expect(has_parsing_errors).to eq(false)
        end
      end

      describe 'false values' do
        let(:false_examples) do
          [
            'F',
            'FALse',
            'N',
            'no',
            '0',
            'OFF',
            'bad value'
          ]
        end

        it 'false values are false' do
          expect(false_examples.any? { |value| model.parse_boolean(field_name, parsing_errors, value) }).to eq(false)
          expect(has_parsing_errors).to eq(false)
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

    describe 'nil value' do
      let(:value) { nil }

      it 'has no errors' do
        expect(subject).to eq(nil)
        expect(has_parsing_errors).to eq(false)
      end
    end
  end
end
