# Transfer record of an attempt, including one that was rejected

class Transfer < ApplicationRecord
  OUTCOMES = %w[applied rejected].freeze

  belongs_to :upload
  # When there is an error/unknown account this can be null
  belongs_to :from_account, class_name: "Account", optional: true
  belongs_to :to_account, class_name: "Account", optional: true

  enum :outcome, OUTCOMES.index_with(&:itself), validate: true

  validates :row_number, presence: true, numericality: { greater_than: 0 }
  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :reason, presence: true, if: :rejected?
end
