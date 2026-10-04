module ImportErrors
  module Transfers
    class Error < StandardError; end

    class FileMissingError < Error; end

    class EmptyFileError < Error; end

    class DateAlreadyProcessedError < Error; end

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
