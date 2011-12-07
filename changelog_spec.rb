# coding: utf-8

$:.unshift(File.dirname(__FILE__))

require 'rspec'
require 'rr'
require 'pry'

require 'changelog2qfixhowm'

RSpec.configure {|config|
  config.mock_with :rr
}

describe "Changelog.parse" do
  let(:entries) {
    <<-_
2011-07-25 yoppi <y.hirokazu@gmail.com>

\t*[test] テストのエントリ
\t本日は晴天なり
\t*[test2][test3] テストのエントリ2
\t本日は快晴なり

2011-07-24 yoppi <y.hirokazu@gmail.com>

\t*[test] テストのエントリ
\t本日は雨天なり
\t*[test2][test3] テストのエントリ2
\t本日は嵐なり
_
  }

  before do
    @io = Object.new
    mock(@io).read.with_any_args { entries }
  end

  it "changelog形式のメモを日付で分割できること" do
    chunks = Changelog.split_each_date(@io)
    chunks.each {|chunk|
      date, body = chunk
      date.should =~ /\d{4}-\d{2}-\d{2}/
      body.should_not be_nil
    }
  end

  it "changelog形式のメモをエントリ毎に分割できること" do
    entries = Changelog.split_each_entry(Changelog.split_each_date(@io))
    entries.keys.size.should == 2
  end
end
