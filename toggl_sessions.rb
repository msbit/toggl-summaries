#!/usr/bin/env ruby

# frozen_string_literal: true

require 'bundler'

Dir.chdir(__dir__) { Bundler.require }

require_relative 'toggl.rb'

SINCE = ARGV[0]
UNTIL = ARGV[1]
DATABASE = ARGV[2]
TASK = ARGV[3]

response = Toggl.get(SINCE, UNTIL)
database = SQLite3::Database.new DATABASE

sessions = {}

rows = response.parsed_response
rows.shift

until rows.empty?
  row = rows.shift
  task = row[4]
  next unless TASK.nil? || task == TASK

  # sessions
  sessions[task] = [] unless sessions.key?(task)
  sessions[task] << row
end

database.execute(
  'INSERT INTO job (client, description) VALUES (?, ?)',
  [ENV['CLIENT_ID'], "BEAT CF Portal (#{SINCE} - #{UNTIL})"]
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
