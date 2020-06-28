#!/usr/bin/env ruby

# frozen_string_literal: true

require 'optparse'

require 'bundler'

Dir.chdir(__dir__) { Bundler.require }

require_relative 'toggl.rb'

def job_insert(database, client, description)
  job_binds = [client, description]
  database.execute(<<-SQL, job_binds)
    INSERT INTO job (client, description)
    VALUES (?, ?)
  SQL
  database.execute(<<-SQL)
    SELECT MAX(id) FROM job
  SQL
end

def line_item_insert(database, job, rate, description, fixed_price, fixed_price_amount)
  line_item_binds = [job, rate, description, fixed_price, fixed_price_amount]
  database.execute(<<-SQL, line_item_binds)
    INSERT INTO line_item (job, rate, description, fixed_price, fixed_price_amount)
    VALUES (?, ?, ?, ?, ?)
  SQL
  database.execute(<<-SQL)
    SELECT MAX(id) FROM line_item
  SQL
end

def session_insert(database, line_item, description, start_time, end_time)
  session_binds = [line_item, description, start_time, end_time]
  database.execute(<<-SQL, session_binds)
    INSERT INTO session (line_item, description, start_time, end_time)
    VALUES (?, ?, ?, ?)
  SQL
  database.execute(<<-SQL)
    SELECT MAX(id) FROM session
  SQL
end

options = {
  grouping: 'task'
}
custom_query = {}

parser = OptionParser.new do |opts|
  opts.on('--database DATABASE') { |o| options[:database] = o }
  opts.on('--database-client-id DATABASE-CLIENT-ID') do |o|
    options[:database_client_id] = o
  end
  opts.on('--name NAME') { |o| options[:name] = o }
  opts.on('--since SINCE') { |o| options[:since] = o }
  opts.on('--until UNTIL') { |o| options[:until] = o }
  opts.on('--workspace WORKSPACE') { |o| custom_query[:workspace_name] = o }

  opts.on('--[no-]billable') { |o| custom_query[:billable] = o ? 'yes' : 'no' }
  opts.on('--client CLIENT') { |o| custom_query[:client_name] = o }
  opts.on('--grouping GROUPING') { |o| options[:grouping] = o }
  opts.on('--project PROJECT') { |o| custom_query[:project_name] = o }
  opts.on('--tag TAG') { |o| custom_query[:tag_name] = o }
  opts.on('--task TASK') { |o| custom_query[:task_name] = o }
end

parser.parse!

raise OptionParser::MissingArgument, 'database' if options[:database].nil?
if options[:database_client_id].nil?
  raise OptionParser::MissingArgument, 'database-client-id'
end
raise OptionParser::MissingArgument, 'name' if options[:name].nil?
raise OptionParser::MissingArgument, 'since' if options[:since].nil?
raise OptionParser::MissingArgument, 'until' if options[:until].nil?
if custom_query[:workspace_name].nil?
  raise OptionParser::MissingArgument, 'workspace'
end

code, response = Toggl.report_details(
  options[:since],
  options[:until],
  custom_query
)

if code != 200
  puts "Error: #{code}"

  if response.is_a?(Hash) && response['error']
    puts response['error']['message']
    puts response['error']['tip']
  end

  exit
end

database = SQLite3::Database.new options[:database]

sessions = {}

response.shift

until response.empty?
  row = response.shift
  group = case options[:grouping]
          when 'task'
            row[4]
          when 'description'
            row[5]
          else
            'UNDEFINED'
          end
  group ||= 'UNDEFINED'

  # sessions
  sessions[group] = [] unless sessions.key?(group)
  sessions[group].push(row)
end

result = job_insert(database, options[:database_client_id], options[:name])

job_id = result[0][0]

sessions.each do |grouping, grouped_rows|
  result = line_item_insert(database, job_id, ENV['RATE_ID'], grouping, 0, 0)
  line_item_id = result[0][0]

  grouped_rows.each do |grouped_row|
    start_time = Time.new(
      *grouped_row[7].split('-'),
      *grouped_row[8].split(':')
    )
    end_time = Time.new(
      *grouped_row[9].split('-'),
      *grouped_row[10].split(':')
    )
    session_insert(
      database,
      line_item_id,
      grouped_row[5],
      start_time.to_i,
      end_time.to_i
    )
  end
end

puts job_id
