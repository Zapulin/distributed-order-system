class Order < ApplicationRecord
  has_many :order_items, dependent: :destroy

  STATUSES = %w[CREATED RESERVED CONFIRMED CANCELLED].freeze

  validates :status, inclusion: { in: STATUSES }
  validates :total_amount, presence: true, numericality: { greater_than: 0 }
end
