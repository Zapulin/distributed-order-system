class OrderItem < ApplicationRecord
  belongs_to :order

  validates :product_id, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :unit_price, presence: true, numericality: { greater_than: 0 }
end
