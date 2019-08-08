require 'spec_helper'

describe Schema::Parsers::American do
  let(:model_class_name) { 'ModelClass' + SecureRandom.hex(10) }
  let(:model_class) do
    kls = Struct.new(
      :time,
      :date
    ) do
      include Schema::Parsers::American

      def parsing_errors
        @parsing_errors ||= ::Schema::Errors.new
      end
    end
    Object.const_set(model_class_name, kls)
    Object.const_get(model_class_name)
  end
  let(:model_time) { Time.now }
  let(:model_date) { model_time.to_date }
  let(:model) { model_class.new(model_time, model_date) }
  let(:parsing_errors) { model.parsing_errors }
  let(:has_parsing_errors) { ! parsing_errors.empty? }

  context 'parse_american_time' do
    let(:field_name) { :time }
    let(:value) { model_time }
    subject { model.parse_american_time(field_name, parsing_errors, value) }

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
      let(:value) { time.strftime('%m/%d/%Y %H:%M:%S') }

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

  context 'parse_american_date' do
    let(:field_name) { :date }
    let(:value) { model_date }
    subject { model.parse_american_date(field_name, parsing_errors, value) }

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
      let(:value) { date.strftime('%m/%d/%Y') }

      it 'has no errors' do
        expect(subject).to eq(date)
        expect(has_parsing_errors).to eq(false)
      end

      describe 'invalid time format' do
        let(:value) { time.to_s }

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
end
