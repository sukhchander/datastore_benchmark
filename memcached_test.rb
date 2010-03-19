#!/usr/bin/env ruby

require "rubygems"

require "memcache"
memcache_options = {
  :debug => true,
  :readonly => false,
  :urlencode => false,
  :compression => false,
  :namespace => "20x200"
}
memcache_servers = ["127.0.0.1:11211"]
db = MemCache.new(memcache_servers, memcache_options)

require "benchmarking"
include Benchmarking

n = 100000

items=[]
for i in 0...n
    items << { :id => i, :message => "foobar" }
end

db.flush_all
s = elapsed do
  for i in 0...n
    db[i] = items[i]
  end
end
puts "* %i sets / second for %i items in %0.2f seconds" % [n/s, n, s]

s = elapsed do
  for i in 0...n
    item = db[i]
    item[:id] == i or raise "Mismatch! Expected #{i}, got: #{item.inspect}"
  end
end
puts "* %i gets / second for %i items in %0.2f seconds" % [n/s, n, s]

=begin
ruby 1.8.7 w/ memcache-client 1.7.7
* 6312 sets / second for 10000 items in 1.58 seconds
* 5657 gets / second for 10000 items in 1.77 seconds

ruby 1.8.7 w/ memcache-client 1.7.7
* 4320 sets / second for 100000 items in 23.14 seconds
* 4008 gets / second for 100000 items in 24.95 seconds
=end
