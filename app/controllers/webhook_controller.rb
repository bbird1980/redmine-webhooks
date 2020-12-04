require_dependency '../helpers/webhook_helper'

class WebhookController < ApplicationController
  unloadable

  # old rails < 5.1
  # before_filter :find_project_by_project_id, :authorize
  # rails >= 5.1
  before_action :find_project_by_project_id, :authorize

  def save_settings
    # fixme: куда-то надо добавить проверку юзера
    # User.current.allowed_to?(:save_webhook_settings, @project)
    # fixme: @project.module_enabled?("webhook") надо вынести в before_action
    if @project.module_enabled?("webhook") && params[:webhook_settings] then
      begin
        model = WebhooksSettings.where(:project_id => @project.id).first_or_create
        model[:urls] = params[:webhook_settings][:urls]
        model.save
        flash[:notice] = l(:notice_successful_save)
      rescue => e
        Rails.logger.error "[WebhookController::save_settings] Create or update error: #{e.message}"
        flash[:error] = "#{l(:notice_failed_save)}: #{e.message}"
      end
    end
    redirect_to :controller => 'projects', :action => 'settings', :id => @project, :tab => params[:tab]
  end
end
