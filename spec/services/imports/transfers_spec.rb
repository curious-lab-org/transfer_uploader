require 'rails_helper'

RSpec.describe Imports::Transfers do
  subject(:call) { described_class.new(upload: upload).call }

  # The balances every example starts from, matching valid_account_balances.csv.
  OPENING_BALANCES = {
    "1111234522226789" => 500_000,
    "1111234522221234" => 1_000_000,
    "2222123433331212" => 55_000,
    "1212343433335665" => 120_000,
    "3212343433335755" => 5_000_000
  }.freeze

  let(:filename) { 'valid_transfers.csv' }
  let(:upload) { build_upload(filename) }

  def build_upload(filename, business_date: Date.new(2026, 10, 4))
    upload = Upload.create!(business_date:)
    path = Rails.root.join('spec/fixtures/files/imports', filename)
    upload.file.attach(io: path.open, filename:, content_type: 'text/csv')
    upload
  end

  def balance(number)
    Account.find_by(number:).balance_cents
  end

  before do
    OPENING_BALANCES.each do |number, cents|
      Account.create!(number:, balance_cents: cents, opening_balance_cents: cents)
    end
  end

  it "records a transfer for every line" do
    expect { call }.to change(Transfer, :count).by(4)
  end

  it "applies every line" do
    call

    expect(upload.transfers.reload.map(&:outcome)).to all(eq("applied"))
  end

  it "carries the line's position, accounts and amount in cents" do
    call
    transfer = upload.transfers.reload.first

    expect(transfer).to have_attributes(
      row_number: 1,
      outcome: "applied",
      from_account: Account.find_by(number: "1111234522226789"),
      to_account: Account.find_by(number: "1212343433335665"),
      amount_cents: 50_000,
      reason: nil
    )
  end

  it "debits the source accounts" do
    call

    expect(balance("3212343433335755")).to eq(4_867_950)
  end

  it "credits the destination accounts" do
    call

    expect(balance("1212343433335665")).to eq(172_560)
  end

  it "leaves the money in the system untouched" do
    expect { call }.not_to change { Account.sum(:balance_cents) }
  end

  it "leaves the opening balances alone" do
    expect { call }.not_to change { Account.sum(:opening_balance_cents) }
  end

  context "when a line is refused by a rule" do
    let(:filename) { 'rejected_transfers.csv' }

    it "records every line, refused or not" do
      expect { call }.to change(Transfer, :count).by(4)
    end

    it "rejects a transfer the source account can't cover" do
      call

      expect(upload.transfers.reload.first).to have_attributes(
        row_number: 1,
        outcome: "rejected",
        reason: "insufficient funds",
        amount_cents: 10_000_000
      )
    end

    it "leaves the overdrawn account's balance alone" do
      expect { call }.not_to change { balance("2222123433331212") }
    end

    it "rejects a transfer from an account we don't hold" do
      call

      expect(upload.transfers.reload.second).to have_attributes(
        row_number: 2,
        outcome: "rejected",
        reason: "unknown account 9999999999999999",
        from_account: nil,
        to_account: Account.find_by(number: "1111234522226789")
      )
    end

    it "rejects a transfer to an account we don't hold" do
      call

      expect(upload.transfers.reload.third).to have_attributes(
        row_number: 3,
        outcome: "rejected",
        reason: "unknown account 9999999999999999",
        from_account: Account.find_by(number: "1111234522226789"),
        to_account: nil
      )
    end

    it "still applies the rest of the file" do
      call

      expect(upload.transfers.reload.fourth).to have_attributes(
        row_number: 4,
        outcome: "applied",
        amount_cents: 10_000,
        reason: nil
      )
    end

    it "moves the money the applied line asked for" do
      expect { call }.to change { balance("1212343433335665") }.by(10_000)
    end
  end

  context "when file is empty" do
    let(:filename) { 'empty_transfers.csv' }

    it 'raises EmptyFileError' do
      expect { call }.to raise_error(ImportErrors::Transfers::EmptyFileError)
    end
  end

  context "when file contains invalid data" do
    let(:filename) { 'invalid_transfers.csv' }

    it 'raises InvalidFileDataError' do
      expect { call }.to raise_error(ImportErrors::Transfers::InvalidFileDataError)
    end

    it 'reports every unparseable line, not just the first' do
      expect { call }.to raise_error(ImportErrors::Transfers::InvalidFileDataError) { |error|
        expect(error.row_errors.map(&:line_number)).to eq([ 2, 3 ])
      }
    end

    it 'records no transfers' do
      expect { call rescue nil }.not_to change(Transfer, :count)
    end

    it 'moves no money, including for the lines that did parse' do
      expect { call rescue nil }.not_to change { balance("1111234522226789") }
    end
  end

  context "when file is missing" do
    before { upload.file.blob.delete }

    it 'raises FileMissingError' do
      expect { call }.to raise_error(ImportErrors::Transfers::FileMissingError)
    end
  end

  context "when the business date already has a completed upload" do
    before { build_upload('valid_transfers.csv').update!(state: :completed) }

    it 'raises DateAlreadyProcessedError' do
      expect { call }.to raise_error(ImportErrors::Transfers::DateAlreadyProcessedError)
    end

    it 'records no transfers' do
      expect { call rescue nil }.not_to change(Transfer, :count)
    end
  end

  context "when another business date has a completed upload" do
    before do
      build_upload('valid_transfers.csv', business_date: Date.new(2026, 10, 3))
        .update!(state: :completed)
    end

    it 'applies the file' do
      expect { call }.to change(Transfer, :count).by(4)
    end
  end
end
