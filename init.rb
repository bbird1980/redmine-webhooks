require 'redmine'

require_dependency 'webhook_listener'

require 'projects_helper_patch' if Redmine::VERSION::MAJOR < 4

Redmine::Plugin.register :webhook do
  name 'Webhook plugin'
  author 'Evgeny Denisyuk'
  description 'Webhook plugin alerts bot about issues create/update'
  version '0.0.1'

  project_module :webhook do
    permission :save_webhook_settings, {:webhook => [:save_settings]}
  end
end
