require 'rails_helper'

RSpec.describe ProcessUploadJob do
  subject(:perform) { described_class.perform_now(upload) }

  let(:filename) { 'valid_transfers.csv' }
  let(:upload) { build_upload(filename) }

  def build_upload(filename, business_date: Date.new(2026, 10, 4))
    upload = Upload.create!(business_date:)
    path = Rails.root.join('spec/fixtures/files/imports', filename)
    upload.file.attach(io: path.open, filename:, content_type: 'text/csv')
    upload
  end

  def balance(number)
    Account.find_by(number:).balance_cents
  end

  before do
    {
      "1111234522226789" => 500_000,
      "1111234522221234" => 1_000_000,
      "2222123433331212" => 55_000,
      "1212343433335665" => 120_000,
      "3212343433335755" => 5_000_000
    }.each do |number, cents|
      Account.create!(number:, balance_cents: cents, opening_balance_cents: cents)
    end
  end

  it "applies every line of the file" do
    expect { perform }.to change(Transfer, :count).by(4)
  end

  it "completes the upload" do
    perform

    expect(upload.reload).to have_attributes(state: "completed", error_message: nil)
  end

  it "moves the money" do
    expect { perform }.to change { balance("1212343433335665") }.by(52_560)
  end

  context "when the upload is not pending" do
    before { upload.update!(state: :processing) }

    it 'applies nothing, so a second run of the same upload is harmless' do
      expect { perform }.not_to change(Transfer, :count)
    end

    it 'moves no money' do
      expect { perform }.not_to change { Account.sum(:balance_cents) }
    end

    it 'leaves the state alone' do
      perform

      expect(upload.reload.state).to eq("processing")
    end
  end

  context "when a line can't be parsed" do
    let(:filename) { 'invalid_transfers.csv' }

    it 'fails the run' do
      perform

      expect(upload.reload.state).to eq("failed")
    end

    it 'keeps every parse error, so the company can fix the whole file' do
      perform

      expect(upload.reload.error_message).to include("line 2", "line 3")
    end

    it 'records no transfers' do
      expect { perform }.not_to change(Transfer, :count)
    end

    it 'moves no money' do
      expect { perform }.not_to change { Account.sum(:balance_cents) }
    end
  end

  context "when the business date already has a completed upload" do
    before { build_upload('valid_transfers.csv').update!(state: :completed) }

    it 'fails the run' do
      perform

      expect(upload.reload.state).to eq("failed")
    end

    it 'names the date in the error' do
      perform

      expect(upload.reload.error_message).to include("2026-10-04")
    end

    it 'applies nothing, so the day cannot be applied twice' do
      expect { perform }.not_to change(Transfer, :count)
    end
  end
end
