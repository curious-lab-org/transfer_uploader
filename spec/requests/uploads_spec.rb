require "rails_helper"

RSpec.describe "Uploads", type: :request do
  let(:csv) { fixture_file_upload("imports/valid_transfers.csv", "text/csv") }

  def build_upload(business_date:, state: :pending, error_message: nil, filename: "transfers.csv")
    upload = Upload.new(business_date:, state:, error_message:)
    upload.file.attach(
      io: Rails.root.join("spec/fixtures/files/imports/valid_transfers.csv").open,
      filename:,
      content_type: "text/csv"
    )
    upload.save!
    upload
  end

  def build_account(number)
    Account.create!(number:, opening_balance_cents: 100_000, balance_cents: 100_000)
  end

  describe "GET /uploads" do
    it "lists uploads newest first with their state" do
      build_upload(business_date: Date.new(2026, 10, 1), state: :completed, filename: "oldest.csv")
      build_upload(business_date: Date.new(2026, 10, 2), state: :pending, filename: "newest.csv")

      get uploads_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("oldest.csv", "newest.csv")
      expect(response.body.index("newest.csv")).to be < response.body.index("oldest.csv")
      expect(response.body).to include("state--completed", "state--pending")
    end

    it "shows the error message for a failed upload" do
      build_upload(
        business_date: Date.new(2026, 10, 3),
        state: :failed,
        error_message: "line 7: amount \"-50\" - must be positive"
      )

      get uploads_path

      expect(response.body).to include("line 7: amount")
      expect(response.body).to include("upload-error")
    end

    it "invites an upload when there are none" do
      get uploads_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("No uploads yet")
    end
  end

  describe "GET /uploads/new" do
    it "renders a multipart form defaulting to today" do
      get new_upload_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('enctype="multipart/form-data"')
      expect(response.body).to include(Date.current.to_s)
    end
  end

  describe "POST /uploads" do
    it "creates the upload, attaches the file and enqueues processing" do
      expect {
        post uploads_path, params: { upload: { business_date: "2026-10-04", file: csv } }
      }.to change(Upload, :count).by(1)

      upload = Upload.last
      expect(upload.business_date).to eq(Date.new(2026, 10, 4))
      expect(upload.file).to be_attached
      expect(upload).to be_pending
      expect(ProcessUploadJob).to have_been_enqueued.with(upload)
      expect(response).to redirect_to(uploads_path)
    end

    it "re-renders the form and enqueues nothing when no file is attached" do
      expect {
        post uploads_path, params: { upload: { business_date: "2026-10-04" } }
      }.not_to change(Upload, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("File must be provided")
      expect(ProcessUploadJob).not_to have_been_enqueued
    end
  end

  describe "GET /uploads/:id" do
    it "lists applied and rejected transfers with amounts and reasons" do
      from = build_account("1" * 16)
      to = build_account("2" * 16)
      upload = build_upload(business_date: Date.new(2026, 10, 2), state: :completed)
      upload.transfers.create!(
        row_number: 1, outcome: :applied, from_account: from, to_account: to, amount_cents: 125_000
      )
      upload.transfers.create!(
        row_number: 2, outcome: :rejected, from_account: from, to_account: nil,
        amount_cents: 1_000, reason: "unknown account #{'9' * 16}"
      )

      get upload_path(upload)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("$1,250.00")
      expect(response.body).to include("$10.00")
      expect(response.body).to include(from.number, to.number)
      expect(response.body).to include("unknown account #{'9' * 16}")
      expect(response.body).to include("outcome--applied", "outcome--rejected")
    end

    it "shows the failure message for a failed upload" do
      upload = build_upload(
        business_date: Date.new(2026, 10, 3),
        state: :failed,
        error_message: "line 9: to_account \"123\" - expected 16 digits"
      )

      get upload_path(upload)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("line 9: to_account")
    end

    it "says so when an upload produced no transfers" do
      upload = build_upload(business_date: Date.new(2026, 10, 4))

      get upload_path(upload)

      expect(response.body).to include("No transfers")
    end

    it "404s for an unknown upload" do
      get upload_path(id: 0)

      expect(response).to have_http_status(:not_found)
    end
  end
end
