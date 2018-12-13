#!/usr/bin/env ruby
# frozen_string_literal: true

class Timestamp
  include(Comparable)

  attr_reader(:year, :month, :day, :hour, :minute)

  def initialize(year:, month:, day:, hour:, minute:)
    @year = year
    @month = month
    @day = day
    @hour = hour
    @minute = minute
  end

  def <=>(other)
    y = year <=> other.year
    return y if y.nil? || y.nonzero?

    m = month <=> other.month
    return m if m.nil? || m.nonzero?

    d = day <=> other.day
    return d if d.nil? || d.nonzero?

    h = hour <=> other.hour
    return h if h.nil? || h.nonzero?

    minute <=> other.minute
  end

  def to_s
    format("[%04d-%02d-%02d %02d:%02d]", year, month, day, hour, minute)
  end
end

class LogEntry
  include(Comparable)

  attr_reader(:timestamp)

  def initialize(timestamp)
    @timestamp = timestamp
  end

  def <=>(other)
    timestamp <=> other.timestamp
  end
end

class WakesUp < LogEntry
  def visit(visitor)
    visitor.on_wakes_up(timestamp)
  end

  def to_s
    "wakes up @ #{timestamp}"
  end
end

class FallsAsleep < LogEntry
  def visit(visitor)
    visitor.on_falls_asleep(timestamp)
  end

  def to_s
    "falls asleep @ #{timestamp}"
  end
end

class BeginsShift < LogEntry
  attr_reader(:guard_id)

  def initialize(timestamp, guard_id)
    super(timestamp)
    @guard_id = guard_id
  end

  def visit(visitor)
    visitor.on_begins_shift(timestamp, guard_id)
  end

  def to_s
    "guard ##{guard_id} begins shift @ #{timestamp}"
  end
end

class Log
  attr_reader(:entries)

  def initialize(entries)
    @entries = entries
  end
end

class LogFile
  attr_reader(:path)

  def initialize(path)
    @path = path
  end

  def read
    entries = []
    File.open(path) do |file|
      file.each_line do |line|
        entry = read_line(line)
        entries.push(entry) if entry
      end
    end
    entries.sort!
    Log.new(entries)
  end

  private

  def read_line(line)
    return unless /
      \A\[
      (?<year> \d+) -
      (?<month> \d+) -
      (?<day> \d+) \s
      (?<hour> \d+) :
      (?<minute> \d+)
      \]\s
      (?:
      (?<wakes_up> wakes \s up) |
      (?<falls_asleep> falls \s asleep) |
      (?<begins_shift> Guard \s \# (?<guard_id> \d+) \s begins \s shift)
      )
      \n\z
    /x =~ line

    timestamp = Timestamp.new(
      year: year.to_i,
      month: month.to_i,
      day: day.to_i,
      hour: hour.to_i,
      minute: minute.to_i,
    )
    if wakes_up
      WakesUp.new(timestamp)
    elsif falls_asleep
      FallsAsleep.new(timestamp)
    elsif begins_shift
      BeginsShift.new(timestamp, guard_id.to_i)
    end
  end
end

class SleepCounter
  attr_reader(:time_asleep)

  def initialize
    @time_asleep = Hash.new do |hash, key|
      hash[key] = []
    end
    @current_guard_id = nil
    @fell_asleep_at = nil
  end

  def process_log(log)
    log.entries.each do |entry|
      entry.visit(self)
    end
  end

  def winner_by_total
    best_guard_id = nil
    best_naps = []
    best_total_minutes_asleep = 0
    time_asleep.each do |guard_id, naps|
      total_minutes_asleep = naps.sum(&:size)
      if total_minutes_asleep > best_total_minutes_asleep
        best_guard_id = guard_id
        best_naps = naps
        best_total_minutes_asleep = total_minutes_asleep
      end
    end

    _, best_minute = best_minute(best_naps)
    [best_guard_id, best_minute]
  end

  def winner_by_minute
    best_guard_id = nil
    best_minute = nil
    best_minutes_asleep = 0
    time_asleep.each do |guard_id, naps|
      minutes_asleep, minute = best_minute(naps)
      if minutes_asleep > best_minutes_asleep
        best_guard_id = guard_id
        best_minute = minute
        best_minutes_asleep = minutes_asleep
      end
    end

    [best_guard_id, best_minute]
  end

  def on_wakes_up(timestamp)
    time_asleep[@current_guard_id].push(@fell_asleep_at.minute...timestamp.minute)
  end

  def on_falls_asleep(timestamp)
    @fell_asleep_at = timestamp
  end

  def on_begins_shift(_timestamp, guard_id)
    @current_guard_id = guard_id
  end

  private

  def best_minute(naps)
    minutes = [0] * 60
    naps.each do |nap|
      nap.each do |minute|
        minutes[minute] += 1
      end
    end
    minutes.each_with_index.max_by { |entry| entry[0] }
  end
end

log_file = LogFile.new("./repose-record.txt")
log = log_file.read
sleep_counter = SleepCounter.new
sleep_counter.process_log(log)

best_guard_id, best_minute = sleep_counter.winner_by_total
puts("winner by total: guard ##{best_guard_id} on minute #{best_minute} (#{best_guard_id * best_minute})")

best_guard_id, best_minute = sleep_counter.winner_by_minute
puts("winner by minute: guard ##{best_guard_id} on minute #{best_minute} (#{best_guard_id * best_minute})")
