# frozen_string_literal: true

require "bigdecimal"
require "csv"

# Parse initial balances CSV
# Uses Enumerable so provides an interface can iterate through each line easily
# Will return Row objects for valid lines, and RowError objects for invalid lines
class Parsers::Balances
  include Enumerable

  Row = Data.define(:line_number, :number, :amount_cents, :success)
  RowError = Data.define(:line_number, :field, :value, :message, :success)

  AMOUNT_FORMAT = /\A\d{1,13}(\.\d{1,2})?\z/

  def initialize(io:)
    @io = io
    @seen = Set.new
  end

  def each
    io.each_line.with_index(1) do |line, line_number|
      yield parse(line, line_number)
    end
  end

  private

  attr_reader :io, :seen

  def parse(line, line_number)
    fields = begin
      CSV.parse_line(line)
    rescue CSV::MalformedCSVError
      nil
    end

    if fields.blank? || fields.size != 2
      return error(line_number, :line, line.chomp, "expected two fields")
    end

    number, amount = fields.map { |field| field.to_s.strip }

    if !number.match?(Account::NUMBER_FORMAT)
      return error(line_number, :number, number, "expected 16 digits")
    end

    if !amount.match?(AMOUNT_FORMAT)
      return error(line_number, :amount, amount, "invalid amount")
    end

    if seen.include?(number)
      return error(line_number, :account, number, "duplicate account number")
    end

    seen << number
    Row.new(line_number:, number:, amount_cents: (BigDecimal(amount) * 100).to_i, success: true)
  end

  def error(line_number, field, value, message)
    RowError.new(line_number:, field:, value:, message:, success: false)
  end
end
