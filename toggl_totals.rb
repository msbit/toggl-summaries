#!/usr/bin/env ruby

# frozen_string_literal: true

require 'optparse'

require 'bundler'

Dir.chdir(__dir__) { Bundler.require }

require_relative 'toggl.rb'

HOURS_PER_DAY = 8.0

options = {
  grouping: 'task'
}
custom_query = {}

parser = OptionParser.new do |opts|
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

totals = {}

rows = response
rows.shift

until rows.empty?
  row = rows.shift
  group = case options[:grouping]
          when 'task'
            row[4]
          when 'description'
            row[5]
          else
            'UNDEFINED'
          end
  group ||= 'UNDEFINED'
  duration = row[11].split(':')

  # totals
  totals[group] = 0 unless totals.key?(group)
  totals[group] += duration.map(&:to_f).reduce { |a, v| (a * 60) + v }
end

total = 0
totals.sort.each do |k, v|
  task_total = v / (3600 * HOURS_PER_DAY)
  total += task_total
  printf("%<k>s %<task_total>.2f\n", k: k, task_total: task_total)
end

printf("\nTOTAL %<total>.2f\n", total: total)
