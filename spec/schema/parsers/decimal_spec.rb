# frozen_string_literal: true

require 'spec_helper'

describe Schema::Parsers::Decimal do
  let(:model_class) do
    Class.new do
      include Schema::All

      attribute :amount, :decimal
    end
  end

  def parse(value)
    model_class.from_hash(amount: value)
  end

  it 'parses strings, integers, rationals, floats and decimals' do
    expect(parse(' 12.50 ').amount).to eq(BigDecimal('12.5'))
    expect(parse('-.5').amount).to eq(BigDecimal('-0.5'))
    expect(parse('1.5e3').amount).to eq(BigDecimal('1500'))
    expect(parse(3).amount).to eq(BigDecimal('3'))
    expect(parse(Rational(1, 4)).amount).to eq(BigDecimal('0.25'))
    expect(parse(1.1).amount).to eq(BigDecimal('1.1'))
    expect(parse(BigDecimal('7')).amount).to eq(BigDecimal('7'))
  end

  it 'parses blank strings and nil to nil without errors' do
    expect(parse(' ').amount).to be_nil
    expect(parse(nil).parsing_errors).to be_empty
  end

  it 'records bad values as parsing errors' do
    expect(parse('12abc').parsing_errors.details).to eq(amount: [{ error: :invalid }])
    expect(parse(Float::NAN).parsing_errors.details).to eq(amount: [{ error: :incompatible }])
    expect(parse([1]).parsing_errors.details).to eq(amount: [{ error: :incompatible }])
    expect(parse(Object.new).parsing_errors.details).to eq(amount: [{ error: :unhandled_type }])
  end
end
