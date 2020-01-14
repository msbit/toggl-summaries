# frozen_string_literal: true

class Toggl
  include HTTParty

  base_uri 'https://toggl.com'

  def self.report_details(since_date, until_date, custom_query = {})
    if client_name = custom_query.delete(:client_name)
      client = clients.find {|c| c['name'] == client_name }
      custom_query[:client_ids] = client['id'] unless client.nil?
    end
    if project_name = custom_query.delete(:project_name)
      project = projects.find {|p| p['name'] == project_name }
      custom_query[:project_ids] = project['id'] unless project.nil?
    end
    if tag_name = custom_query.delete(:tag_name)
      tag = tags.find {|t| t['name'] == tag_name }
      custom_query[:tag_ids] = tag['id'] unless tag.nil?
    end
    if task_name = custom_query.delete(:task_name)
      task = tasks.find {|t| t['name'] == task_name }
      custom_query[:task_ids] = task['id'] unless task.nil?
    end
    if workspace_name = custom_query.delete(:workspace_name)
      workspace = workspaces.find {|t| t['name'] == workspace_name }
      custom_query[:workspace_id] = workspace['id'] unless workspace.nil?
    end

    query = {
      billable: 'both',
      client_ids: '',
      description: '',
      distinct_rates: 'off',
      or_members_of_group_ids: '',
      order_desc: 'off',
      order_field: 'date',
      page: '1',
      project_ids: '',
      rounding: 'off',
      since: since_date,
      tag_ids: '',
      task_ids: '',
      until: until_date,
      user_agent: 'https://github.com/msbit/toggl-summaries',
      user_ids: '',
      workspace_id: ''
    }.merge(custom_query)

    get(
      '/reports/api/v2/details.csv',
      basic_auth: {
        username: ENV['API_TOKEN'],
        password: 'api_token'
      },
      query: query
    ).parsed_response
  end

  class << self
    [:clients, :projects, :tags, :tasks, :workspaces].each do |attribute|
      define_method attribute do
        get(
          "/api/v9/me/#{attribute}",
          basic_auth: {
            username: ENV['API_TOKEN'],
            password: 'api_token'
          }
        ).parsed_response
      end
    end
  end
end
