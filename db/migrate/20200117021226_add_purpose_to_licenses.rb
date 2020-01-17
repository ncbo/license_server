class AddPurposeToLicenses < ActiveRecord::Migration[5.1]
  def up
    execute <<-SQL
        ALTER TABLE licenses ADD purpose enum('non_profit_research_individual', 'non_profit_research_team', 'non_profit_public_portal', 'education', 'non_profit_other', 'commercial_research', 'commercial_managing_semantic_resources', 'commercial_public_portal', 'commercial_other') NOT NULL;
    SQL
  end

  def down
    remove_column :licenses, :purpose
  end
end
