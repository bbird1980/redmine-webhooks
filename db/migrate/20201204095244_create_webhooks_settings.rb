class CreateWebhooksSettings < ActiveRecord::Migration[5.2]
  def self.up
    create_table :webhooks_settings do |t|
      t.column :project_id, :integer
      t.column :urls, :text
    end
    add_index :webhooks_settings, :project_id
  end

  def self.down
    drop_table :webhooks_settings
  end
end
