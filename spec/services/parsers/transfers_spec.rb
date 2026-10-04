require 'rails_helper'

RSpec.describe Parsers::Transfers do
  subject(:results) { described_class.new(io: StringIO.new(csv)).to_a }

  let(:csv) { "1111234522226789,1212343433335665,500.00\n" }

  it "yields one Row" do
    expect(results.map(&:class)).to eq([ Parsers::Transfers::Row ])
  end

  it "carries the line number, both account numbers and the amount in cents" do
    expect(results.first).to have_attributes(
      line_number: 1,
      from_number: "1111234522226789",
      to_number: "1212343433335665",
      amount_cents: 50_000,
      success: true
    )
  end

  context "when data is missing" do
    let(:csv) { "1111234522226789,1212343433335665,500.00\n1111234522226789,500.00\n" }

    it 'yields a row error' do
      expect(results.second).to have_attributes(
        line_number: 2,
        field: :line,
        value: "1111234522226789,500.00",
        message: "expected three fields",
        success: false
      )
    end
  end

  context "when invalid from account number" do
    let(:csv) { "11113234522226789,1212343433335665,500.00" }

    it "yields a row error" do
      expect(results.first).to have_attributes(
        line_number: 1,
        field: :from_account,
        value: "11113234522226789",
        message: "expected 16 digits",
        success: false
      )
    end
  end

  context "when invalid to account number" do
    let(:csv) { "1111234522226789,121234343333566,500.00" }

    it "yields a row error" do
      expect(results.first).to have_attributes(
        line_number: 1,
        field: :to_account,
        value: "121234343333566",
        message: "expected 16 digits",
        success: false
      )
    end
  end

  context "when transferring to the same account" do
    let(:csv) { "1111234522226789,1111234522226789,500.00" }

    it "yields a row error" do
      expect(results.first).to have_attributes(
        line_number: 1,
        field: :to_account,
        value: "1111234522226789",
        message: "same as from account",
        success: false
      )
    end
  end

  context "when invalid amount" do
    let(:csv) { "1111234522226789,1212343433335665,abc" }

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

  context "when amount is zero" do
    let(:csv) { "1111234522226789,1212343433335665,0.00" }

    it "yields a row error" do
      expect(results.first).to have_attributes(
        line_number: 1,
        field: :amount,
        value: "0.00",
        message: "must be greater than zero",
        success: false
      )
    end
  end
end
