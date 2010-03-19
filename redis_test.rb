#!/usr/bin/env ruby

require "rubygems"

require "redis"
redis_options = {
    :db => 7,
    :port => "6379",
    :server => "localhost",
    :namespace => "20x200"
}
db = Redis.new(redis_options)

require 'benchmarking'
include Benchmarking

n = 100000

items = []
for i in 0...n
  items << [i,"foobar"]
end

db.flush_all
s = elapsed do
  for i in 0...n
    db[i] = items[i]
  end
end
puts "* %i sets / sec individually for %i items in %0.2f seconds" % [n/s, n, s]

s = elapsed do
  for i in 10...n
    item = db[i]
    item.delete("foobar").to_i == i or raise "Mismatch! Expected #{i}, got: #{item.inspect}"
  end
end
puts "* %i gets / sec individually for %i items in %0.2f seconds" % [n/s, n, s]

=begin
ruby 1.8.7 w/ ezmobius-redis-rb 0.1
* 12020 sets / sec individually for 10000 items in 0.83 seconds
* 11459 gets / sec individually for 10000 items in 0.87 seconds

ruby 1.8.7 w/ redis 0.1.2
* 10109 sets / sec individually for 10000 items in 0.99 seconds
* 9954 gets / sec individually for 10000 items in 1.00 seconds

ruby 1.8.7 w/ ezmobius-redis-rb 0.1
* 12272 sets / sec individually for 100000 items in 8.15 seconds
* 11749 gets / sec individually for 100000 items in 8.51 seconds
=end
