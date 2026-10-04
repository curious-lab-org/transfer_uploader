# frozen_string_literal: true

# Service object for importing initial balances
class Imports::InitialBalances
  def initialize(path:, parser: Parsers::Balances)
    @path = path
    @parser = parser
  end

  def call
    rows, row_errors = read.partition(&:success)

    raise ImportErrors::InitialBalances::EmptyFileError, path.to_s if rows.empty? && row_errors.empty?
    raise ImportErrors::InitialBalances::InvalidFileDataError, row_errors if row_errors.any?

    create(rows)
  end

  private

  attr_reader :path, :parser

  def read
    File.open(path, "r") { |file| parser.new(io: file).to_a }
  rescue Errno::ENOENT, Errno::EISDIR, TypeError
    raise ImportErrors::InitialBalances::FileNotFoundError, path.to_s
  end

  # Ignore existing accounts
  def create(rows)
    Account.transaction do
      existing = Account.where(number: rows.map(&:number)).pluck(:number)

      rows.reject { |row| existing.include?(row.number) }.map do |row|
        Account.create!(number: row.number,
          balance_cents: row.amount_cents,
          opening_balance_cents: row.amount_cents)
      end
    end
  end
end
