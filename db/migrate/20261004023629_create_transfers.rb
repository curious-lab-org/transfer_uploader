class CreateTransfers < ActiveRecord::Migration[8.1]
  def change
    create_table :transfers do |t|
      t.references :upload, null: false, foreign_key: true
      t.integer :row_number, null: false
      t.string :outcome, null: false
      t.references :from_account, foreign_key: { to_table: :accounts }
      t.references :to_account, foreign_key: { to_table: :accounts }
      t.bigint :amount_cents, null: false
      t.string :reason

      t.timestamps
    end

    add_index :transfers, [ :upload_id, :row_number ], unique: true
  end
end
