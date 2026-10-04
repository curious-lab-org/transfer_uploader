# frozen_string_literal: true

module ImportErrors
  module InitialBalances
    class Error < StandardError; end

    class FileNotFoundError < Error; end

    class EmptyFileError < Error; end

    # Raised when any line fails to parse. Carries every failure, not just
    # the first, so one run reports the whole file.
    class InvalidFileDataError < Error
      attr_reader :row_errors

      def initialize(row_errors = [])
        @row_errors = row_errors
        super(row_errors.map { |row_error|
          "line #{row_error.line_number}: #{row_error.field} " \
            "#{row_error.value.inspect} - #{row_error.message}"
        }.join("\n").presence || "invalid file data")
      end
    end
  end
end
