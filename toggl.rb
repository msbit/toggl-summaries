# frozen_string_literal: true

class Toggl
  include HTTParty

  base_uri 'https://toggl.com'

  def self.report_details(since_date, until_date, custom_query = {})
    query = {
      bars_count: '31',
      billable: 'both',
      bookmark_token: '',
      calculate: 'time',
      client_ids: '',
      date_format: 'DD.MM.YYYY',
      datepage: '1',
      description: '',
      distinct_rates: 'Off',
      name: '',
      or_members_of_group_ids: '',
      order_desc: 'off',
      order_field: 'date',
      page: '1',
      period: 'prevWeek',
      project_ids: ENV['PROJECT_ID'],
      rounding: 'Off',
      since: since_date,
      sortBy: 'date',
      sortDirection: 'asc',
      status: 'active',
      subgrouping: 'users',
      subgrouping_ids: 'true',
      tag_ids: '',
      task_ids: '',
      time_format_mode: 'improved',
      until: until_date,
      user_agent: 'Snowball',
      user_ids: '',
      with_total_currencies: '1',
      workspace_id: ENV['WORKSPACE_ID']
    }.merge(custom_query)

    get(
      '/reports/api/v2/details.csv',
      basic_auth: {
        username: ENV['API_TOKEN'],
        password: 'api_token'
      },
      query: query
    )
  end

  def self.tags
    get(
      '/api/v9/me/tags',
      basic_auth: {
        username: ENV['API_TOKEN'],
        password: 'api_token'
      }
    )
  end
end
