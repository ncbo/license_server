class CreateLicensePurposes < ActiveRecord::Migration[5.1]
  def up
    create_table :license_purposes do |t|
      t.string :name, null: false
      t.integer :sort_order, null: false
    end

    add_index :license_purposes, :sort_order, unique: true
    add_column :licenses, :license_purpose_id, :bigint, null: false
    add_foreign_key :licenses, :license_purposes
  end

  def down
    remove_foreign_key :licenses, :license_purposes
    remove_column :licenses, :license_purpose_id
    remove_index :license_purposes, :sort_order
    drop_table :license_purposes
  end
end
