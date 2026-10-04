require 'rails_helper'

RSpec.describe Parsers::Balances do
  subject(:results) { described_class.new(io: StringIO.new(csv)).to_a }

  let(:csv) { "1111234522226789,5000.00\n" }

  it "yields one Row" do
    expect(results.map(&:class)).to eq([ Parsers::Balances::Row ])
  end

  it "carries the line number, number and amount in cents" do
    expect(results.first).to have_attributes(
      line_number: 1,
      number: "1111234522226789",
      amount_cents: 500_000,
      success: true
    )
  end

  context "when data is missing" do
    let(:csv) { "1111234522226789,5000.00\n100.00\n" }

    it 'yields a row error' do
      expect(results.second).to have_attributes(
        line_number: 2,
        field: :line,
        value: "100.00",
        message: "expected two fields",
        success: false
      )
    end
  end

  context "when an account number is duplicated" do
    let(:csv) { "1111234522226789,5000.00\n1111234522226789,100.00\n" }

    it "yields a row error" do
      expect(results.second).to have_attributes(
        line_number: 2,
        field: :account,
        value: "1111234522226789",
        message: "duplicate account number",
        success: false
      )
    end
  end

  context "when invalid account number" do
    let(:csv) { "11113234522226789,5000.00" }

    it "yields a row error" do
      expect(results.first).to have_attributes(
        line_number: 1,
        field: :number,
        value: "11113234522226789",
        message: "expected 16 digits",
        success: false
      )
    end
  end

  context "when invalid amount" do
    let(:csv) { "1111234522226789,abc" }

    it "yields a row error" do
      expect(results.first).to have_attributes(
        line_number: 1,
        field: :amount,
        value: "abc",
        message: "invalid amount",
        success: false
      )
    end
  end
end
