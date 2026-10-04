# frozen_string_literal: true

# Applies one day's transfers file. ADR-10: out of the request, one at a time.
class ProcessUploadJob < ApplicationJob
  queue_as :default

  # For safety only allow one upload to be processed at a time
  limits_concurrency to: 1, key: ->(_upload) { "transfers_upload" }, duration: 10.minutes

  def perform(upload)
    return if !upload.pending?

    upload.processing!

    Upload.transaction do
      Imports::Transfers.new(upload:).call

      upload.completed!
    end
  rescue ImportErrors::Transfers::Error => e
    # A refused date, a missing file, an empty file, or a line we couldn't parse.
    fail_run(upload, e.message)
  rescue StandardError => e
    fail_run(upload, "#{e.class}: #{e.message}")
    raise
  end

  private

  def fail_run(upload, error_message)
    upload.update!(state: :failed, error_message:)
  end
end
