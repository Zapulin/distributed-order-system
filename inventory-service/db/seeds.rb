# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

products = [
  { product_id: "PROD-001", quantity: 100 },
  { product_id: "PROD-002", quantity: 50 },
  { product_id: "PROD-003", quantity: 10 },
  { product_id: "PROD-OUT", quantity: 0 }
]

products.each do |attrs|
  ProductStock.find_or_create_by!(product_id: attrs[:product_id]) do |ps|
    ps.quantity = attrs[:quantity]
  end
  puts "ProductStock for #{attrs[:product_id]}: #{ProductStock.find_by(product_id: attrs[:product_id]).quantity} units"
end
