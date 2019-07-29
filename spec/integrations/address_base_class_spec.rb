require 'spec_helper'

# reuse the same address schema for shipping and billing address
describe 'Reused address base_class' do
  let(:address_schema_class) do
    kls = Class.new do
      include ::Schema::Model

      attribute :first_name, :string
      attribute :last_name, :string
      attribute :address1, :string
      attribute :address2, :string
      attribute :address3, :string
      attribute :state, :string
      attribute :city, :string
      attribute :zip_code, :string
    end
    class_name = 'Address' + SecureRandom.hex(8)
    Object.const_set(class_name, kls)
    Object.const_get(class_name)
  end
  let(:checkout_schema_class) do
    base_class = address_schema_class
    kls = Class.new do
      include ::Schema::Model
      include ::Schema::Associations::HasOne

      has_one(:shipping_address, base_class: base_class)
      has_one(:billing_address, base_class: base_class) do
        attribute :same_as_shipping_address, :boolean
      end
    end
  end

  let(:payload) do
    {
      shipping_address: {
        first_name: 'Jon',
        last_name: 'Smith',
        address1: '3rd Franklin St.',
        state: 'GA',
        city: 'Atlanta',
        zip_code: '29101'
      },
      billing_address: {
        same_as_shipping_address: true
      }
    }
  end

  subject { checkout_schema_class.from_hash(payload) }

  it 'uses the same base schema class to create new schemas' do
    expect(subject.parsing_errors.empty?).to eq(true)
    expect(subject.shipping_address.first_name).to eq('Jon')
    expect(subject.billing_address.first_name).to eq(nil)
    expect(subject.billing_address.same_as_shipping_address).to eq(true)
  end
end

