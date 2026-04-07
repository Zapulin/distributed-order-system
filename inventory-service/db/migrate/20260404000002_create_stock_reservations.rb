class CreateStockReservations < ActiveRecord::Migration[8.1]
  def change
    create_table :stock_reservations, id: :uuid do |t|
      t.string :order_id, null: false
      t.string :product_id, null: false
      t.integer :quantity, null: false
      t.string :status, null: false, default: "pending" # pending, released, expired
      t.datetime :expires_at, null: false
      t.timestamps
    end

    add_index :stock_reservations, :order_id
  end
end
