#!/usr/bin/env ruby

# frozen_string_literal: true

require 'bundler'

Bundler.require

require './toggl.rb'

HOURS_PER_DAY = 8.0

SINCE = ARGV[0]
UNTIL = ARGV[1]

response = Toggl.get(SINCE, UNTIL)

totals = {}

rows = CSV.parse(response.body)
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
