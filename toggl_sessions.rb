#!/usr/bin/env ruby

# frozen_string_literal: true

require 'optparse'

require 'bundler'

Dir.chdir(__dir__) { Bundler.require }

require_relative 'toggl.rb'

options = {}
custom_query = {}

parser = OptionParser.new do |opts|
  opts.on('--database DATABASE') { |o| options[:database] = o }
  opts.on('--since SINCE') { |o| options[:since] = o }
  opts.on('--until UNTIL') { |o| options[:until] = o }
  opts.on('--workspace WORKSPACE') { |o| custom_query[:workspace_name] = o }

  opts.on('--[no-]billable') { |o| custom_query[:billable] = o ? 'yes' : 'no' }
  opts.on('--client CLIENT') { |o| custom_query[:client_name] = o }
  opts.on('--project PROJECT') { |o| custom_query[:project_name] = o }
  opts.on('--tag TAG') { |o| custom_query[:tag_name] = o }
  opts.on('--task TASK') { |o| custom_query[:task_name] = o }
end

parser.parse!

raise OptionParser::MissingArgument, 'database' if options[:database].nil?
raise OptionParser::MissingArgument, 'since' if options[:since].nil?
raise OptionParser::MissingArgument, 'until' if options[:until].nil?
raise OptionParser::MissingArgument, 'workspace' if custom_query[:workspace_name].nil?

response = Toggl.report_details(options[:since], options[:until], custom_query)
database = SQLite3::Database.new options[:database]

sessions = {}

rows = response
rows.shift

until rows.empty?
  row = rows.shift
  task = row[4] || 'UNDEFINED'

  # sessions
  sessions[task] = [] unless sessions.key?(task)
  sessions[task] << row
end

database.execute(
  'INSERT INTO job (client, description) VALUES (?, ?)',
  [ENV['CLIENT_ID'], "BEAT CF Portal (#{options[:since]} - #{options[:until]})"]
)
result = database.execute('SELECT MAX(id) FROM job')
job_id = result[0][0]

sessions.each do |task, rows|
  database.execute(
    'INSERT INTO line_item (job, rate, description, fixed_price, fixed_price_amount) VALUES (?, ?, ?, ?, ?)',
    [job_id, ENV['RATE_ID'], task, 0, 0]
  )
  result = database.execute('SELECT MAX(id) FROM line_item')
  line_item_id = result[0][0]

  rows.each do |row|
    start_time = Time.new(*row[7].split('-'), *row[8].split(':'))
    end_time = Time.new(*row[9].split('-'), *row[10].split(':'))
    database.execute(
      'INSERT INTO session (line_item, description, start_time, end_time) VALUES (?, ?, ?, ?)',
      [line_item_id, row[5], start_time.to_i, end_time.to_i]
    )
  end
end

puts job_id
