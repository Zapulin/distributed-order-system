class ProductStock < ApplicationRecord
  validates :product_id, presence: true, uniqueness: true
  validates :quantity, numericality: { greater_than_or_equal_to: 0, only_integer: true }
end
