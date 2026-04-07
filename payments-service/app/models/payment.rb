class Payment < ApplicationRecord
  STATUSES = %w[pending succeeded failed].freeze

  validates :order_id, presence: true, uniqueness: true
  validates :amount, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: STATUSES }
end
