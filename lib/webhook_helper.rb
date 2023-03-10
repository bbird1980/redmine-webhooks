require 'net/http'
require 'uri'
require 'open-uri'
require 'json'

module Redmine
  module Helpers
    module Webhook
      def self.issue_as_json(issue: nil, journals: nil)
        json = {}
        json[:id] = issue.id
        json[:project] = {:id => issue.project_id, :name => issue.project.name} unless issue.project.nil?
        json[:tracker] = {:id => issue.tracker_id, :name => issue.tracker.name} unless issue.tracker.nil?
        json[:status] = {:id => issue.status_id, :name => issue.status.name} unless issue.status.nil?
        json[:priority] = {:id => issue.priority_id, :name => issue.priority.name} unless issue.priority.nil?
        json[:author] = {:id => issue.author_id, :name => issue.author.name, :login => issue.author.login} unless issue.author.nil?
        json[:assigned_to] = {:id => issue.assigned_to_id, :name => issue.assigned_to.name, :login => issue.assigned_to.login} unless issue.assigned_to.nil?
        json[:subject] = issue.subject
        json[:description] = issue.description

        unless issue.custom_field_values.nil?
          json[:custom_fields] = []
          issue.custom_field_values.each do |custom_value|
            attrs = {:id => custom_value.custom_field_id, :name => custom_value.custom_field.name}
            attrs.merge!(:multiple => true) if custom_value.custom_field.multiple?

            if custom_value.value.is_a?(Array)
              attrs[:value] = []
              custom_value.value.each do |value|
                attrs[:value] += [value] unless value.blank?
              end
            else
              attrs[:value] = custom_value.value
            end
          json[:custom_fields] += [attrs]
          end
        end

        unless journals.nil?
          json[:journals] = []
          journals.each do |journal|
            j = {}
            j[:id] = journal.id
            j[:user] = {:id => journal.user_id, :name => journal.user.name, :login => journal.user.login} unless journal.user.nil?
            j[:notes] = journal.notes
            j[:private_notes] = journal.private_notes
            j[:created_on] = journal.created_on
            j[:details] = []
            journal.visible_details.each do |detail|
              j[:details] += [{
                :property => detail.property,
                :name => detail.prop_key,
                :old_value => detail.old_value,
                :new_value => detail.value
              }]
            end
            json[:journals] += [j]
          end
        end

	json[:watchers] = []
	issue.watchers.each do |watcher|
	  json[:watchers] += [{:id => watcher.user.id, :name => watcher.user.name, :login => watcher.user.login}]
	end

	json[:tags] = issue.tags

        json[:journals_full] = []
        issue.journals().each do |journal|
          j = {}
          j[:id] = journal.id
          j[:user] = {:id => journal.user_id, :name => journal.user.name, :login => journal.user.login} unless journal.user.nil?
          j[:notes] = journal.notes
          j[:private_notes] = journal.private_notes
          j[:created_on] = journal.created_on
          j[:details] = []
          journal.visible_details.each do |detail|
            j[:details] += [{
              :property => detail.property,
              :name => detail.prop_key,
              :old_value => detail.old_value,
              :new_value => detail.value
            }]
          end
          json[:journals_full] += [j]
        end

        json
      end

      def self.send_event(project_id: nil, action: nil, data: nil)
        model = WebhooksSettings[project_id]
        raise "notice_not_found" unless model
        raise "notice_not_found" if model[:urls].empty?

        # split urls by \n
        urls = model[:urls].split(/\r?\n/).reject(&:empty?)
        # call each url
        urls.each do |url|
            begin
              uri = URI.parse(url)
            rescue => e
              Rails.logger.error "[Redmine::Helpers::Webhook::send_event] Parsing webhook failed: #{e.message}"
              raise "notice_invalid"
              return
            end
            unless uri.kind_of?(URI::HTTP) or uri.kind_of?(URI::HTTPS)
              Rails.logger.error "[Redmine::Helpers::Webhook::send_event] Parsing webhook failed: must be http or https"
              raise "notice_invalid"
              return
            end

            http = Net::HTTP.new(uri.host, uri.port)
            http.open_timeout = 1 #1 sec
            http.read_timeout = 1 #1 sec
            if uri.scheme == 'https'
              http.use_ssl = true
              http.verify_mode = OpenSSL::SSL::VERIFY_NONE
            end
            request = Net::HTTP::Post.new(uri.request_uri, 'Content-Type' => 'application/json')
            request.body = { :action => action, :data => data }.to_json

            begin
              response = http.request(request)
            rescue => e
              Rails.logger.error "[Redmine::Helpers::Webhook::send_event] Webhook request failed:\n"\
                                 "  URI: #{uri}\n"\
                                 "  Exception: #{e.message}"
              # fixme: add locale
              raise "Http error: #{e.message}"
              return
            end

            unless response.code.to_i == 200
              Rails.logger.error "[Redmine::Helpers::Webhook::send_event] Webhook request failed:\n"\
                                 "  URI: #{uri}\n"\
                                 "  Response code: #{response.code}"
              # fixme: add locale
              raise "Response code #{response.code}"
              return
            else
              Rails.logger.info "[Redmine::Helpers::Webhook::send_event] Webhook success:\n"\
                                "  URI: #{uri}\n"\
                                "  Response code: #{response.code}"
            end
        end
      end
    end
  end
end
