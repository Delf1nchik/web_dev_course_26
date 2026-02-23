#!/usr/bin/env ruby
# encoding: UTF-8

require 'date'

def abort_with(message)
  puts "Error: #{message}"
  exit(1)
end

if ARGV.length != 4
  abort_with("Usage: ruby build_calendar.rb teams.txt 01.08.2026 01.06.2027 calendar.txt")
end

teams_file, start_date_str, end_date_str, output_file = ARGV

abort_with("Teams file not found") unless File.exist?(teams_file)

begin
  start_date = Date.strptime(start_date_str, "%d.%m.%Y")
  end_date   = Date.strptime(end_date_str, "%d.%m.%Y")
rescue
  abort_with("Dates must be in format DD.MM.YYYY")
end

abort_with("Start date must be before end date") if start_date >= end_date

# --------------------------
# ===== READ TEAMS =========
# --------------------------

teams = []

File.open(teams_file, "r:utf-8") do |file|
  file.each_with_index do |line, index|
    line.strip!
    next if line.empty?

    # Убираем нумерацию "1. "
    line = line.sub(/^\d+\.\s*/, "")

    # Разделяем по тире (длинное или короткое)
    parts = line.split(/\s+—\s+/)

    abort_with("Invalid format in teams file line #{index + 1}") unless parts.size == 2

    name = parts[0].strip
    city = parts[1].strip

    abort_with("Empty team name in line #{index + 1}") if name.empty?
    abort_with("Empty city in line #{index + 1}") if city.empty?

    teams << { name: name, city: city }
  end
end

abort_with("Need at least 2 teams") if teams.size < 2

# --------------------------
# ===== GENERATE MATCHES ===
# --------------------------

matches = []

teams.each_with_index do |home, i|
  teams.each_with_index do |away, j|
    next if i == j
    matches << { home: home, away: away }
  end
end

# --------------------------
# ===== GENERATE SLOTS =====
# --------------------------

valid_days = [5, 6, 0]
times = ["12:00", "15:00", "18:00"]

slots = []
current_date = start_date

while current_date <= end_date
  if valid_days.include?(current_date.wday)
    times.each do |time|
      2.times { slots << { date: current_date, time: time } }
    end
  end
  current_date += 1
end

abort_with("Not enough time slots for all matches") if matches.size > slots.size

# --------------------------
# ===== DISTRIBUTION =======
# --------------------------

interval = slots.size.to_f / matches.size
scheduled = []

matches.each_with_index do |match, i|
  slot_index = (i * interval).floor
  scheduled << match.merge(slots[slot_index])
end

scheduled.sort_by! { |m| [m[:date], m[:time]] }

# --------------------------
# ===== OUTPUT =============
# --------------------------

File.open(output_file, "w:utf-8") do |file|
  file.puts "SPORT CALENDAR"
  file.puts "Period: #{start_date.strftime('%d %B %Y')} - #{end_date.strftime('%d %B %Y')}"
  file.puts "-" * 60

  current_date = nil

  scheduled.each do |game|
    if game[:date] != current_date
      file.puts
      file.puts game[:date].strftime("%A, %d %B %Y")
      file.puts "-" * 40
      current_date = game[:date]
    end

    file.puts "#{game[:time]} | #{game[:home][:name]} (#{game[:home][:city]}) vs #{game[:away][:name]} (#{game[:away][:city]})"
  end
end

puts "Calendar successfully created: #{output_file}"