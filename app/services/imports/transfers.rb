# frozen_string_literal: true

# Service object for importing transfers
class Imports::Transfers
  def initialize(upload:, parser: Parsers::Transfers, applier: Transfers::Apply)
    @upload = upload
    @parser = parser
    @applier = applier
  end

  def call
    # raise if already completed
    if Upload.completed.where(business_date: upload.business_date).exists?
      raise ImportErrors::Transfers::DateAlreadyProcessedError, upload.business_date.to_s
    end

    rows = read

    Upload.transaction do
      apply(rows)
    end
  end

  private

  attr_reader :upload, :parser, :applier

  def read
    rows, row_errors = upload.file.open { |file| parser.new(io: file).to_a }.partition(&:success)


    raise ImportErrors::Transfers::EmptyFileError, upload.id.to_s if rows.empty? && row_errors.empty?
    raise ImportErrors::Transfers::InvalidFileDataError, row_errors if row_errors.any?

    rows

  rescue ActiveStorage::FileNotFoundError
    raise ImportErrors::Transfers::FileMissingError, upload.id.to_s
  end

  def apply(rows)
    apply = applier.new(upload:, accounts: account_ids)

    rows.each { |row| apply.call(row) }
  end

  # This will return a hash mapping account number to account id
  # e.g. {"1234567890123456" => 1, "2345678901234567" => 2}
  def account_ids
    Account.pluck(:number, :id).to_h
  end
end
