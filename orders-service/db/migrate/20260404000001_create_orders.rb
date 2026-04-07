class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders, id: :uuid do |t|
      t.string :status, null: false, default: "CREATED"
      t.decimal :total_amount, precision: 10, scale: 2, null: false
      t.timestamps
    end
  end
end
