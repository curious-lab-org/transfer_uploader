require 'rails_helper'

RSpec.describe Account do
  def build_account(attributes = {})
    described_class.new(
      { number: '1111234522226789', opening_balance_cents: 500_000, balance_cents: 500_000 }
        .merge(attributes)
    )
  end

  it 'is valid with a 16 digit number and non-negative balances' do
    expect(build_account).to be_valid
  end

  describe 'number' do
    it 'is required' do
      account = build_account(number: nil)

      expect(account).not_to be_valid
      expect(account.errors[:number]).to include("can't be blank")
    end

    it 'rejects fewer than 16 digits' do
      account = build_account(number: '111123452222678')

      expect(account).not_to be_valid
      expect(account.errors[:number]).to include('is invalid')
    end

    it 'rejects more than 16 digits' do
      account = build_account(number: '11112345222267891')

      expect(account).not_to be_valid
      expect(account.errors[:number]).to include('is invalid')
    end

    it 'rejects digits grouped with spaces' do
      account = build_account(number: '1111 2345 2222 6789')

      expect(account).not_to be_valid
      expect(account.errors[:number]).to include('is invalid')
    end

    it 'rejects digits grouped with hyphens' do
      account = build_account(number: '1111-2345-2222-6789')

      expect(account).not_to be_valid
      expect(account.errors[:number]).to include('is invalid')
    end

    it 'rejects surrounding whitespace rather than stripping it' do
      account = build_account(number: ' 1111234522226789 ')

      expect(account).not_to be_valid
      expect(account.errors[:number]).to include('is invalid')
    end

    it 'rejects a number already taken by another account' do
      build_account.save!
      duplicate = build_account(opening_balance_cents: 1, balance_cents: 1)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:number]).to include('has already been taken')
    end

    it 'allows a different number' do
      build_account.save!

      expect(build_account(number: '1111234522221234')).to be_valid
    end

    it 'keeps leading zeros' do
      account = build_account(number: '0111234522226789')
      account.save!

      expect(account.reload.number).to eq('0111234522226789')
    end
  end

  describe 'opening_balance_cents' do
    it 'is required' do
      account = build_account(opening_balance_cents: nil)

      expect(account).not_to be_valid
      expect(account.errors[:opening_balance_cents]).to include("can't be blank")
    end

    it 'rejects a negative balance' do
      account = build_account(opening_balance_cents: -1)

      expect(account).not_to be_valid
      expect(account.errors[:opening_balance_cents])
        .to include('must be greater than or equal to 0')
    end

    it 'allows a zero balance' do
      expect(build_account(opening_balance_cents: 0)).to be_valid
    end
  end

  describe 'balance_cents' do
    it 'is required' do
      account = build_account(balance_cents: nil)

      expect(account).not_to be_valid
      expect(account.errors[:balance_cents]).to include("can't be blank")
    end

    it 'rejects a negative balance' do
      account = build_account(balance_cents: -1)

      expect(account).not_to be_valid
      expect(account.errors[:balance_cents]).to include('must be greater than or equal to 0')
    end

    it 'allows a zero balance' do
      expect(build_account(balance_cents: 0)).to be_valid
    end
  end
end
