#!/usr/bin/env ruby

require "rubygems"
require "voldemort-rb"

db = VoldemortClient.new("benchmark","localhost:6666")

require 'benchmarking'
include Benchmarking

n = 100000

items = []
for i in 0...n
  items[i] = "foobar"
end

s = elapsed do
  for i in 0...n
    db.put(i.to_s,"foobar")
  end
end
puts "* %i sets / sec individually for %i items in %0.2f seconds" % [n/s, n, s]

s = elapsed do
  for i in 0...n
    item = db.get(i.to_s)
    item.eql?"foobar" or raise "Mismatch! Expected #{i}, got: #{item.inspect}"
  end
end
puts "* %i gets / sec individually for %i items in %0.2f seconds" % [n/s, n, s]

=begin
ruby 1.8.7 w/ voldemort-0.80 w/ voldemort-rb w/ java version "1.6.0_17"
* 486 sets / sec individually for 10000 items in 20.54 seconds
* 1231 gets / sec individually for 10000 items in 8.12 seconds

ruby 1.8.7 w/ voldemort-0.80 w/ voldemort-rb w/ java version "1.6.0_17"
* 480 sets / sec individually for 100000 items in 208.32 seconds
* 1203 gets / sec individually for 100000 items in 83.06 seconds
=end
