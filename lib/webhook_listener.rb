require 'webhook_helper'

class WebhookListener < Redmine::Hook::Listener
  def controller_issues_new_after_save(context = {})
    if context[:project].module_enabled?("webhook")
      begin
        data = {
          :issue => Redmine::Helpers::Webhook::issue_as_json(:issue => context[:issue])
        }
        Redmine::Helpers::Webhook::send_event(:project_id => context[:issue][:project_id], :action => :issue_create, :data => data)
      rescue => e
        error = e.message == "notice_not_found" || e.message == "notice_invalid" ? context[:controller].l(e.message) : e.message
        Rails.logger.error "[WebhookListener::controller_issues_new_after_save] Exception: #{error}"
        context[:controller].flash[:error] = error
      end
    end
  end

  def controller_issues_edit_after_save(context = {})
    if context[:project].module_enabled?("webhook")
      begin
        data = {
          :issue => Redmine::Helpers::Webhook::issue_as_json(:issue => context[:issue], :journals => [context[:journal]])
        }
        Redmine::Helpers::Webhook::send_event(:project_id => context[:issue][:project_id], :action => :issue_edit, :data => data)
      rescue => e
        error = e.message == "notice_not_found" || e.message == "notice_invalid" ? context[:controller].l(e.message) : e.message
        Rails.logger.error "[WebhookListener::controller_issues_edit_after_save] Exception: #{error}"
        context[:controller].flash[:error] = error
      end
    end
  end
end
