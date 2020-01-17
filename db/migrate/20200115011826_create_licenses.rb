#rails generate model License bp_username:string:index last_name:string first_name:string organization:string{512} project_info:text reason:text identification:text comments:text appliance_id:string:uniq license_key:string{1024} valid_date:date
class CreateLicenses < ActiveRecord::Migration[5.1]
  def up
    create_table :licenses do |t|
      t.string :bp_username, null: false
      t.string :last_name, null: false
      t.string :first_name, null: false
      t.string :organization, limit: 512, null: false
      t.text :project_info
      t.text :reason
      t.text :identification
      t.text :comments
      t.string :appliance_id, null: false
      t.string :license_key, limit: 1024
      t.date :valid_date, null: false

      t.timestamps
    end
    add_index :licenses, :bp_username
    add_index :licenses, :appliance_id
  end

  def down
    remove_index :licenses, :appliance_id
    remove_index :licenses, :bp_username
    drop_table :licenses
  end
end
