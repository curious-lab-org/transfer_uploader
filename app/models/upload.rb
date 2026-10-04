# Upload record, one per file
class Upload < ApplicationRecord
  # I would consider putting this as AASM states, but keeping as enum for simplicity
  STATES = %w[pending processing completed failed].freeze

  has_one_attached :file
  has_many :transfers, -> { order(:row_number) }, dependent: :destroy

  enum :state, STATES.index_with(&:itself), validate: true

  validates :business_date, presence: true
  validate :file_must_be_attached

  def file_must_be_attached
    errors.add(:file, "must be provided") unless file.attached?
  end
end
