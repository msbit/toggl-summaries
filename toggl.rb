# frozen_string_literal: true

class Toggl
  def self.get(since_date, until_date)
    HTTParty.get(
      'https://toggl.com/reports/api/v2/details.csv',
      query: {
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
      },
      headers: {
        Cookie: "report_user=#{ENV['REPORT_USER']}"
      }
    )
  end
end
