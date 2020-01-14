#!/usr/bin/env ruby

# frozen_string_literal: true

require 'optparse'

require 'bundler'

Dir.chdir(__dir__) { Bundler.require }

require_relative 'toggl.rb'

HOURS_PER_DAY = 8.0

options = {}

parser = OptionParser.new do |opts|
  opts.on('--since SINCE') { |o| options[:since] = o }
  opts.on('--until UNTIL') { |o| options[:until] = o }

  opts.on('--tag TAG') { |o| options[:tag] = o }
end

parser.parse!

raise OptionParser::MissingArgument, 'since' if options[:since].nil?
raise OptionParser::MissingArgument, 'until' if options[:until].nil?

custom_query = {}

if options.key?:tag
  tags = Toggl.tags.parsed_response
  tag = tags.find { |t| t['name'] == options[:tag] }
  custom_query[:tag_ids] = tag['id'] unless tag.nil?
end

response = Toggl.report_details(options[:since], options[:until], custom_query)

totals = {}

rows = response.parsed_response
rows.shift

until rows.empty?
  row = rows.shift
  task = row[4]

  duration = row[11].split(':')

  # totals
  totals[task] = 0 unless totals.key?(task)
  totals[task] += duration.map(&:to_f).reduce { |a, v| (a * 60) + v }
end

total = 0
totals.sort.each do |k, v|
  task_total = v / (3600 * HOURS_PER_DAY)
  total += task_total
  printf("%<k>s %<task_total>.2f\n", k: k, task_total: task_total)
end

printf("\nTOTAL %<total>.2f\n", total: total)
