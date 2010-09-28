#!/usr/bin/env ruby

# set chef config
# node name
# chef config secret
# mixin recipe definition DSL core or chef mixin language
# OR
# Chef::Rest ob
require 'rubygems'
require 'chef'
require 'chef/mixin/language'

USAGE =<<EOH
Usage: #{$0} SHEF_CONFIG

Where SHEF_CONFIG is the name of a shef-style config file.
Example:

node_name       'alice'
client_key      "#{ENV['HOME']}/alcie.pem"
chef_server_url "https://api-preprod.opscode.com/organizations/YOUR_ORG_HERE"

EOH

if ARGV.size != 1
  abort(USAGE)
end

Chef::Config.from_file(ARGV[0])

ALL_TESTS = []

class QueryTest
  include Chef::Mixin::Language

  attr_reader :type, :query, :expected

  def initialize(type, query, expected)
    @type = type
    @query = query
    @expected = Set.new(expected)
  end

  def and(q)
    raise "types must match" unless q.type == @type
    QueryTest.new(@type, "(#{@query} AND #{q.query})",
                  @expected.intersection(q.expected))
  end

  def or(q)
    raise "types must match" unless q.type == @type
    QueryTest.new(@type, "(#{@query} OR #{q.query})",
                  @expected.union(q.expected))
  end

  def show(s)
    s.to_a.join(", ")
  end

  def compare_results(results)
    got = Set.new(results)
    if @expected != got
      puts "FAIL: #{@type} #{@query}"
      puts "expected: #{show(@expected)}"
      puts "     got: #{show(got)}"
      raise "search test failed"
    else
      puts "OK: (#{@expected.size}) #{@type} #{@query}"
    end
    true
  end

  def execute
    compare_results search(@type, @query).map { |o| o.name }
  rescue Exception => e
    puts "ERROR: query failed for #{@query}"
    raise e
  end
end

def query(obj_type, query_string, expected_result)
  q = QueryTest.new(obj_type, query_string, expected_result)
  #q.execute
  ALL_TESTS << q
  q
end

def random_bool_query(queries, n)
  q_count = queries.size
  ops = [:and, :or]
  ans = queries[rand(q_count)]
  n.times do |i|
    ans = ans.send(ops[rand(2)], queries[rand(q_count)])
  end
  ans.execute
end

# Exact searches:
query :node, "tag:apples", ["a"]
query :node, "tag:apes", ["b", "c"]
query :node, "tag:not_a_tag_value", []
query :node, 'run_list:recipe\[bravo\]', ["ab", "b"]
query :node, 'run_list:recipe\[zulu\]', []
query :node, 'run_list:recipe\[alpha\]', ["a", "ab"]

# Prefix searches:

query :node, "tag:a*", ["a", "ab", "b", "c"]
query :node, "tag:app*", ["a"]
query :node, "tag:ap*", ["a", "b", "c"]
query :node, "tag:zulu*", []


# Range searches:

query :node, 'value:[* TO *]', ["a", "b", "c"]
query :node, 'value:[1 TO 2]', ['a', 'b']
query :node, 'value:[1 TO 3]', ['a', 'b', 'c']
query :node, 'value:[2 TO *]', ['b', 'c']
query :node, 'value:[* TO 2]', ['a', 'b']
query :node, 'value:[* TO 5]', ['a', 'b', 'c']
query :node, 'value:[5 TO *]', []
# exclusive range
query :node, 'value:{1 TO 3}', ['b']


# Quotes
query :node, 'multi_word:"foo bar baz"', ['a']
query :node, 'multi_word:foo*', ['a', 'c']

# internal escaped quotes don't work, but prefix query for an escaped
# quote does
# query :node, 'quotes:"\"one\" \"two\" \"three\""', ['ab']
# query :node, 'quotes:\"one\"*', ['ab']
query :node, 'quotes:\"*', ['ab']

# nested keys
query :node, 'nested_b1_a2_a3:B1_A2_A3-a', ['a']
query :node, 'nested_b1_a2_a3:B1_A2_A3-b', ['b']
query :node, 'nested_b1_a2_a3:B1_A2_A3-c', ['c']
query :node, 'nested_a1_b2_a3:A1_B2_A3-*', ['a', 'b', 'c']

# # nested expando (only w/ new stuff)
query :node, 'nested_b1_*_a3:B1_A2_A3-a', ['a']
query :node, 'nested_b1_a2_*:B1_A2_A3-b', ['b']
query :node, 'nested_b1_a2_a3:B1_A2_A3-c', ['c']
query :node, 'nested_*_b2_a3:A1_B2_A3-*', ['a', 'b', 'c']


ALL_TESTS.each do |q|
  q.execute
end

# AND/OR precedence
100.times do |i|
  random_bool_query(ALL_TESTS, 2)
  random_bool_query(ALL_TESTS, 3)
  random_bool_query(ALL_TESTS, 4)
end

