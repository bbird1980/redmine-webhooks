class WebhooksSettings < ActiveRecord::Base
  unloadable

  # belongs_to :project

  def self.[](project_id)
    WebhooksSettings.find_by(:project_id => project_id)
  end
end
