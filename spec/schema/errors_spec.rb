require 'spec_helper'

describe Schema::Errors do
  let(:errors) { Schema::Errors.new }

  context 'empty?' do
    subject { errors.empty? }

    it 'has no errors' do
      expect(subject).to eq(true)
    end

    describe 'with errors' do
      before(:each) do
        errors.add(:name, :invalid)
      end

      it 'has errors' do
        expect(subject).to eq(false)
      end
    end
  end

  context 'add' do
    let(:name) { :cost }
    let(:error) { :invalid }
    subject { errors.add(name, error) }

    it 'adds the error' do
      expect(subject.empty?).to eq(false)
    end
  end

  context '[]' do
    before(:each) do
      errors[:name] = :invalid
    end

    it 'returns an array of errors' do
      expect(errors[:name]).to eq([:invalid])
    end

    it 'returns an empty array' do
      expect(errors[:other].empty?).to eq(true)
    end

    describe 'additional errors' do
      before(:each) do
        errors[:name] = :incompatable
      end

      it 'returns an array of errors' do
        expect(errors[:name]).to eq([:invalid, :incompatable])
      end
    end
  end
end
