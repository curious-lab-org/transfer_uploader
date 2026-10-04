require 'rails_helper'

RSpec.describe Imports::InitialBalances do
  subject(:call) { described_class.new(path: path).call }

  let(:path) { 'spec/fixtures/files/imports/valid_account_balances.csv' }

  it "creates new accounts" do
    expect { call }.to change(Account, :count).by(5)
  end

  it "assigns opening balance and current balance" do
    call
    account = Account.find_by(number: "1111234522226789")

    expect(account).to have_attributes(
      number: "1111234522226789",
      opening_balance_cents: 500_000,
      balance_cents: 500_000
    )
  end

  context "when importing for accounts already existing" do
    before do
      Account.create!(number: "1111234522226789", balance_cents: 1_000_000, opening_balance_cents: 1_000_000)
    end

    it 'does not create duplicate account' do
      expect { call }.to change(Account, :count).by(4)
    end

    it 'does not update existing account' do
      account = Account.find_by(number: "1111234522226789")

      expect(account).to have_attributes(
        number: "1111234522226789",
        opening_balance_cents: 1_000_000,
        balance_cents: 1_000_000
      )
    end
  end

  context "when file is missing" do
    let(:path) { 'missing.csv' }

    it 'raises FileNotFoundError' do
      expect { call }.to raise_error(ImportErrors::InitialBalances::FileNotFoundError)
    end
  end

  context "when file is empty" do
    let(:path) { 'spec/fixtures/files/imports/empty_account_balances.csv' }

    it 'raises EmptyFileError' do
      expect { call }.to raise_error(ImportErrors::InitialBalances::EmptyFileError)
    end
  end

  context "when file contains invalid data" do
    let(:path) { 'spec/fixtures/files/imports/invalid_account_balances.csv' }

    it 'raises InvalidFileDataError' do
      expect { call }.to raise_error(ImportErrors::InitialBalances::InvalidFileDataError)
    end
  end
end
