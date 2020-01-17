class AddApprovalStatusToLicenses < ActiveRecord::Migration[5.1]
  def up
    execute <<-SQL
        ALTER TABLE licenses ADD approval_status enum('approved', 'disapproved', 'pending') NOT NULL DEFAULT 'pending';
    SQL
  end

  def down
    remove_column :licenses, :approval_status
  end
end
