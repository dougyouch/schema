require 'spec_helper'
require 'examples/company_schema'

describe 'CompanySchema example' do
  let(:payload) do
    JSON.parse(File.read('spec/examples/company_schema.json'))
  end
  let(:company_schema) { CompanySchema.from_hash(payload) }

  describe 'valid?' do
    subject { company_schema.valid? }

    it 'return true' do
      expect(subject).to eq(true)
      expect(company_schema.parsing_errors.empty?).to eq(true)
    end

    describe 'invalid' do
      before(:each) do
        payload['employees'].first.delete('type')
      end

      it 'return false' do
        expect(subject).to eq(false)
        expect(company_schema.parsing_errors.empty?).to eq(false)
      end

      it 'employees have errors' do
        subject
        expect(company_schema.errors[:employees]).to eq(['is invalid'])
        expect(company_schema.employees.first.errors[:type]).to eq(['is not included in the list'])
        expect(company_schema.employees.first.type).to eq(nil)
      end
    end
  end
end
