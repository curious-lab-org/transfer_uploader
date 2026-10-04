class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.string :number, null: false, limit: 16
      t.bigint :opening_balance_cents, null: false
      t.bigint :balance_cents, null: false

      t.timestamps
    end

    add_index :accounts, :number, unique: true
  end
end
