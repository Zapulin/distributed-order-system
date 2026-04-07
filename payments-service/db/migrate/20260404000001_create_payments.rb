class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments, id: :uuid do |t|
      t.string :order_id, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :status, null: false, default: "pending" # pending, succeeded, failed
      t.timestamps
    end

    add_index :payments, :order_id, unique: true
  end
end
