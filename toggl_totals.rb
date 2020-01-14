#!/usr/bin/env ruby

# frozen_string_literal: true

require 'optparse'

require 'bundler'

Dir.chdir(__dir__) { Bundler.require }

require_relative 'toggl.rb'

HOURS_PER_DAY = 8.0

options = {}

parser = OptionParser.new do |opts|
  opts.on('-s', '--since SINCE') { |o| options[:since] = o }
  opts.on('-u', '--until UNTIL') { |o| options[:until] = o }

  opts.on('-t', '--tag TAG') { |o| options[:tag] = o }
end

parser.parse!

raise OptionParser::MissingArgument, 'since' if options[:since].nil?
raise OptionParser::MissingArgument, 'until' if options[:until].nil?

response = Toggl.get(options[:since], options[:until])

totals = {}

rows = response.parsed_response
rows.shift

until rows.empty?
  row = rows.shift
  tag = row[12]
  unless options[:tag].nil?
    next if tag.nil? || !tag.include?(options[:tag])
  end

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
