# Account record with opening and current balance
class Account < ApplicationRecord
  NUMBER_FORMAT = /\A\d{16}\z/

  validates :number, presence: true, format: { with: NUMBER_FORMAT }, uniqueness: true
  validates :opening_balance_cents, presence: true,
    numericality: { greater_than_or_equal_to: 0 }
  validates :balance_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
