class CreateUploads < ActiveRecord::Migration[8.1]
  def change
    create_table :uploads do |t|
      t.date :business_date, null: false
      t.string :digest, null: false
      t.string :state, null: false, default: "pending"
      t.text :error_message

      t.timestamps
    end

    add_index :uploads, :business_date

    add_index :uploads, :business_date, unique: true, where: "state = 'completed'",
      name: "index_uploads_on_completed_business_date"
  end
end
