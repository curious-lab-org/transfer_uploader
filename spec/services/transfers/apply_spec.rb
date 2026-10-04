require 'rails_helper'

RSpec.describe Transfers::Apply do
  subject(:apply) { described_class.new(upload:, accounts:) }

  let(:from_number) { "1111234522226789" }
  let(:to_number) { "1212343433335665" }
  let(:unknown_number) { "9999999999999999" }

  let(:upload) do
    upload = Upload.new(business_date: Date.new(2026, 10, 4))
    path = Rails.root.join('spec/fixtures/files/imports/valid_transfers.csv')
    upload.file.attach(io: path.open, filename: 'valid_transfers.csv', content_type: 'text/csv')
    upload.save!
    upload
  end
  let(:accounts) { Account.pluck(:number, :id).to_h }

  def create_account(number, cents)
    Account.create!(number:, balance_cents: cents, opening_balance_cents: cents)
  end

  def row(line_number: 1, from: from_number, to: to_number, amount_cents: 50_000)
    Parsers::Transfers::Row.new(line_number:, from_number: from, to_number: to,
      amount_cents:, success: true)
  end

  def balance(number)
    Account.find_by(number:).balance_cents
  end

  before do
    create_account(from_number, 500_000)
    create_account(to_number, 120_000)
  end

  it "records the transfer as applied" do
    apply.call(row(line_number: 7))

    expect(upload.transfers.reload.sole).to have_attributes(
      row_number: 7,
      outcome: "applied",
      from_account: Account.find_by(number: from_number),
      to_account: Account.find_by(number: to_number),
      amount_cents: 50_000,
      reason: nil
    )
  end

  it "debits the source account" do
    expect { apply.call(row) }.to change { balance(from_number) }.by(-50_000)
  end

  it "credits the destination account" do
    expect { apply.call(row) }.to change { balance(to_number) }.by(50_000)
  end

  it "leaves the opening balances alone" do
    expect { apply.call(row) }.not_to change { Account.sum(:opening_balance_cents) }
  end

  describe "the overdraft rule" do
    it "applies a transfer for the account's whole balance" do
      apply.call(row(amount_cents: 500_000))

      expect(upload.transfers.reload.sole.outcome).to eq("applied")
      expect(balance(from_number)).to eq(0)
    end

    it "rejects a transfer one cent beyond the balance" do
      apply.call(row(amount_cents: 500_001))

      expect(upload.transfers.reload.sole).to have_attributes(
        outcome: "rejected",
        reason: "insufficient funds",
        amount_cents: 500_001
      )
    end

    it "moves no money when it rejects" do
      expect { apply.call(row(amount_cents: 500_001)) }
        .not_to change { [ balance(from_number), balance(to_number) ] }
    end

    it "rejects any transfer out of an emptied account" do
      apply.call(row(line_number: 1, amount_cents: 500_000))
      apply.call(row(line_number: 2, amount_cents: 1))

      expect(upload.transfers.reload.second.outcome).to eq("rejected")
    end
  end

  describe "an account we don't hold" do
    it "rejects a transfer from it" do
      apply.call(row(from: unknown_number))

      expect(upload.transfers.reload.sole).to have_attributes(
        outcome: "rejected",
        reason: "unknown account #{unknown_number}",
        from_account: nil,
        to_account: Account.find_by(number: to_number)
      )
    end

    it "rejects a transfer to it" do
      apply.call(row(to: unknown_number))

      expect(upload.transfers.reload.sole).to have_attributes(
        outcome: "rejected",
        reason: "unknown account #{unknown_number}",
        from_account: Account.find_by(number: from_number),
        to_account: nil
      )
    end

    it "does not debit the source when the destination is unknown" do
      expect { apply.call(row(to: unknown_number)) }.not_to change { balance(from_number) }
    end
  end
end
