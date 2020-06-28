# frozen_string_literal: true

class Toggl
  include HTTParty

  DEFAULT_QUERY = {
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
    tag_ids: '',
    task_ids: '',
    user_agent: 'https://github.com/msbit/toggl-summaries',
    user_ids: '',
    workspace_id: ''
  }.freeze

  base_uri 'https://toggl.com'

  def self.get_with_auth(path, options = {}, &block)
    unless options.key?(:basic_auth)
      options[:basic_auth] = {
        username: ENV['API_TOKEN'],
        password: 'api_token'
      }
    end

    get(path, options, &block)
  end

  def self.map_name(input_key, output_key, relation, custom_query)
    return unless (name = custom_query.delete(input_key))

    object = send(relation).find { |c| c['name'] == name }
    return if object.nil?

    custom_query[output_key] = object['id']
  end

  def self.map_names(custom_query)
    map_name(:client_name, :client_ids, :clients, custom_query)
    map_name(:project_name, :project_ids, :projects, custom_query)
    map_name(:tag_name, :tag_ids, :tags, custom_query)
    map_name(:task_name, :task_ids, :tasks, custom_query)
    map_name(:workspace_name, :workspace_id, :workspaces, custom_query)
  end

  def self.report_details(since_date, until_date, custom_query = {})
    map_names(custom_query)

    query = DEFAULT_QUERY.merge(custom_query)
    query[:since] =  since_date
    query[:until] =  until_date

    response = get_with_auth('/reports/api/v2/details.csv', query: query)

    [response.code, response.parsed_response]
  end

  class << self
    %i[clients projects tags tasks workspaces].each do |attribute|
      define_method attribute do
        get_with_auth("/api/v9/me/#{attribute}").parsed_response
      end
    end
  end
end
