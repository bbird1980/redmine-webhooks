module ProjectsHelperPatch
  def self.included(base)
    base.send(:include, InstanceMethods)

    base.class_eval do
      unloadable

      alias_method_chain :project_settings_tabs, :webhook
    end
  end

  module InstanceMethods
    def project_settings_tabs_with_webhook
      tabs = project_settings_tabs_without_webhook
      if @project.module_enabled?(:webhook) && User.current.allowed_to?(:save_settings, @project)
        tabs.push({ :name => 'webhook',
                             :action => :save_settings,
                             :partial => 'projects/settings/webhook',
                             :label => :label_webhook_tab })
      end
      tabs
    end
  end

end

unless ProjectsHelper.included_modules.include?(ProjectsHelperPatch)
  ProjectsHelper.send(:include, ProjectsHelperPatch)
end
