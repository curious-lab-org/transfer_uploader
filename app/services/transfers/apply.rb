# frozen_string_literal: true

# Apply the transfer to an account, debiting one and crediting the other
# Also creates records of both outcomes (applied / rejected)
class Transfers::Apply
  def initialize(upload:, accounts:)
    @upload = upload
    @accounts = accounts
  end

  def call(row)
    from_id = accounts[row.from_number]
    to_id = accounts[row.to_number]

    return reject(row, "unknown account #{row.from_number}") if from_id.nil?
    return reject(row, "unknown account #{row.to_number}") if to_id.nil?
    return reject(row, "insufficient funds") if !debit(from_id, row.amount_cents)

    credit(to_id, row.amount_cents)

    upload.transfers.create!(
      row_number: row.line_number,
      outcome: :applied,
      from_account_id: from_id,
      to_account_id: to_id,
      amount_cents: row.amount_cents
    )
  end

  private

  attr_reader :upload, :accounts

  # Using update_all which helps with concurrency as its all written via sql atomically
  def debit(account_id, amount_cents)
    Account.where(id: account_id)
      .where("balance_cents >= ?", amount_cents)
      .update_all([ "balance_cents = balance_cents - ?, updated_at = ?", amount_cents, Time.current ])
      .positive?
  end

  # Using update_all which helps with concurrency as its all written via sql atomically
  def credit(account_id, amount_cents)
    Account.where(id: account_id)
      .update_all([ "balance_cents = balance_cents + ?, updated_at = ?", amount_cents, Time.current ])
  end

  def reject(row, reason)
    upload.transfers.create!(
      row_number: row.line_number,
      outcome: :rejected,
      reason:,
      from_account_id: accounts[row.from_number],
      to_account_id: accounts[row.to_number],
      amount_cents: row.amount_cents
    )
  end
end
