# frozen_string_literal: true

require "bigdecimal"
require "csv"

# Parse a transfers CSV: from_account,to_account,amount, headerless.
# Uses Enumerable so provides an interface can iterate through each line easily
# Will return Row objects for valid lines, and RowError objects for invalid lines
class Parsers::Transfers
  include Enumerable

  Row = Data.define(:line_number, :from_number, :to_number, :amount_cents, :success)
  RowError = Data.define(:line_number, :field, :value, :message, :success)

  AMOUNT_FORMAT = /\A\d{1,13}(\.\d{1,2})?\z/

  def initialize(io:)
    @io = io
  end

  def each
    io.each_line.with_index(1) do |line, line_number|
      yield parse(line, line_number)
    end
  end

  private

  attr_reader :io

  def parse(line, line_number)
    fields = begin
      CSV.parse_line(line)
    rescue CSV::MalformedCSVError
      nil
    end

    if fields.blank? || fields.size != 3
      return error(line_number, :line, line.chomp, "expected three fields")
    end

    from_number, to_number, amount = fields.map { |field| field.to_s.strip }

    if !from_number.match?(Account::NUMBER_FORMAT)
      return error(line_number, :from_account, from_number, "expected 16 digits")
    end

    if !to_number.match?(Account::NUMBER_FORMAT)
      return error(line_number, :to_account, to_number, "expected 16 digits")
    end

    if from_number == to_number
      return error(line_number, :to_account, to_number, "same as from account")
    end

    if !amount.match?(AMOUNT_FORMAT)
      return error(line_number, :amount, amount, "invalid amount")
    end

    amount_cents = (BigDecimal(amount) * 100).to_i

    if !amount_cents.positive?
      return error(line_number, :amount, amount, "must be greater than zero")
    end

    Row.new(line_number:, from_number:, to_number:, amount_cents:, success: true)
  end

  def error(line_number, field, value, message)
    RowError.new(line_number:, field:, value:, message:, success: false)
  end
end
