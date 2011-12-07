# coding: utf-8
#
# changelog to QFixHowm converter.
#
# Usage:
#   $ ruby changelog2qfixhowm -h {qfixhowm-home} < {changelog}
#

require 'time'
require 'fileutils'

class Changelog

  DATE_REGEXP = /^(\d{4}-?\d{2}-?\d{2})\s+.*?\s+<.*>/
  ENTRY_REGEXP = /\*\s(\[.*\])+:\s(.*)$/

  # IO -> Changelog
  def self.parse(io)
    new(split_each_entry(split_each_date(io)))
  end

  def self.split_each_date(io)
    io.read.split(DATE_REGEXP)[1..-1].each_slice(2)
  end

  def self.split_each_entry(chunks)
    ret = {}
    chunks.each {|chunk|
      date, e = chunk
      entries = e.split(ENTRY_REGEXP)[1..-1].each_slice(3)
      ret[date] = entries
    }
    ret
  end

  def initialize(chunks)
    @entries = chunks.map {|date, entries|
      ChangelogEntry.new(date, entries)
    }
  end
  attr_accessor :entries

  def each_entry(&block)
    @entries.each {|entry|
      yield entry
    }
  end
end

class ChangelogEntry
  def initialize(date, memos)
    @date = date
    @memos = memos.map {|memo|
      tags, title, body = memo
      ChangelogMemo.new({:tags => tags, :title => title, :body => body})
    }
  end
  attr_accessor :date, :memos
end

class ChangelogMemo
  def initialize(memo)
    @tags = memo[:tags]
    @title = memo[:title]
    @body = sanitize(memo[:body])
  end
  attr_reader :tags, :title, :body

  def sanitize(x)
    x.gsub(/^[\t\n ]+/, "")
  end
end

class Converter
  def initialize(changelog)
    @changelog = changelog
  end

  def run
    @changelog.each_entry {|entry|
      d = Time.parse(entry.date) 
      FileUtils.mkdir_p(to_dir_name(d))
      File.open(to_file_name(d), 'w') {|io|
        io.puts(make_howm(entry))
      }
    }
  end

  def to_dir_name(d)
    "#{d.year}/#{sprintf("%02d", d.month)}"
  end

  def to_file_name(d)
    to_dir_name(d) + "/#{d.year}-#{sprintf("%02d", d.month)}-#{sprintf("%02d", d.day)}-#{sprintf("%06d", rand(240000))}.md"
  end

  def make_howm(entry)
    entry = <<-ENTRY
= #{entry.memos.inject("") {|ret, memo| ret << memo.tags}.split(/\[(.*?)\]/).select {|e| e.size != 0}.uniq.inject("") {|ret, e| ret << "[#{e}]"}} #{entry.date}
[#{entry.date} 00:00]

#{entry.memos.inject("") {|ret, memo|
  ret << "## #{memo.title}\n#{memo.body}\n\n"
}}
    ENTRY
    entry
  end
end

if __FILE__ == $0
  Converter.new(Changelog.parse(ARGF)).run
end
