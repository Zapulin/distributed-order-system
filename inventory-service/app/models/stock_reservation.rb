class StockReservation < ApplicationRecord
  STATUSES = %w[pending released expired].freeze

  validates :order_id, presence: true
  validates :product_id, presence: true
  validates :quantity, numericality: { greater_than: 0, only_integer: true }
  validates :status, inclusion: { in: STATUSES }
  validates :expires_at, presence: true

  scope :pending, -> { where(status: "pending") }
  scope :expired_pending, -> { pending.where("expires_at < ?", Time.current) }
end
