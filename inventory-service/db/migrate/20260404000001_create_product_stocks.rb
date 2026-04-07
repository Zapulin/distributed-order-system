class CreateProductStocks < ActiveRecord::Migration[8.1]
  def change
    create_table :product_stocks, id: :uuid do |t|
      t.string :product_id, null: false
      t.integer :quantity, null: false, default: 0
      t.timestamps
    end

    add_index :product_stocks, :product_id, unique: true
  end
end
