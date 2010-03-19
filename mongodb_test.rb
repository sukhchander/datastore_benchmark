#!/usr/bin/env ruby

require 'rubygems'

require 'mongo'
db = Mongo::Connection.new("localhost", 27017).db("benchmark")

categories = [
  { :_id => 1, :title => "Work" },
  { :_id => 2, :title => "Play" },
]

tasks = [
  { :_id => 1, :title => "Finish project", :category_id => 1 },
  { :_id => 2, :title => "Get money in account", :category_id => 1 },
  { :_id => 3, :title => "Go to beach", :category_id => 2 },
  { :_id => 4, :title => "Drink a Corona", :category_id => 2 },
  { :_id => 5, :title => "Read while lying in a hammock", :category_id => 2 }
]

category_collection = db.collection("category")
category_collection.remove
categories.each do |category|
  category_collection << category
end

task_collection = db.collection("task")
task_collection.remove
tasks.each do |task|
  task_collection << task
end
task_collection.create_index("category_id")

task = task_collection.find_one(:_id => 1)
puts "* Find a task by id #1: #{task['title']}"

# Find tasks by category
tasks = task_collection.find(:category_id => 1)
puts "* Find tasks by category #1:"
tasks.each do |task|
  puts "  - #{task['title']}"
end

# Find tasks by substring
tasks = task_collection.find(:title => /in/)
puts "* Query tasks matching regexp /in/:"
tasks.each do |task|
  puts "  - #{task['title']}"
end

benchmark_collection = db.collection("benchmark")
benchmark_collection.create_index("id")

require 'benchmarking'
include Benchmarking

n = 100000

items = []
for i in 0...n
  items << { :id => i, :message => "foobar" }
end

benchmark_collection.remove
s = elapsed do
  for i in 0...n
    benchmark_collection << items[i]
  end
  system "sync"
end
puts "* %i sets / sec individually for %i items in %0.2f seconds" % [n/s, n, s]

benchmark_collection.remove
s = elapsed do
  benchmark_collection.insert(items)
  system "sync"
end
puts "* %i sets / sec as batch for %i items in %0.2f seconds" % [n/s, n, s]

s = elapsed do
  for i in 0...n
    item = benchmark_collection.find_one("id" => i)
    item["id"] == i or raise "Mismatch! Expected #{i}, got: #{item.inspect}"
  end
end
puts "* %i gets / sec individually for %i items in %0.2f seconds" % [n/s, n, s]

seen = {}
s = elapsed do
  benchmark_collection.find.each do |item|
    i = item["id"]
    if seen[i]
      raise "Already saw #{i}"
    else
      seen[i] = true
    end
  end
end
puts "* %i gets / sec as batch for %i items in %0.2f seconds" % [n/s, n, s]

category_collection.remove
task_collection.remove
benchmark_collection.remove

=begin
ruby 1.8.7 w/ mongodb @1.2.1 w/ mongo 0.19.1 gem

* Find a task by id #1: Finish project
* Find tasks by category #1:
  - Finish project
  - Get money in account
* Query tasks matching regexp /in/:
  - Finish project
  - Get money in account
  - Drink a Corona
  - Read while lying in a hammock
* 5058 sets / sec individually for 10000 items in 1.98 seconds
* 830 sets / sec as batch for 10000 items in 12.04 seconds
* 2406 gets / sec individually for 10000 items in 4.16 seconds
* 16640 gets / sec as batch for 10000 items in 0.60 seconds


ruby 1.8.7 w/ mongodb @1.2.1 w/ mongo 0.19.1 gem

* Find a task by id #1: Finish project
* Find tasks by category #1:
  - Finish project
  - Get money in account
* Query tasks matching regexp /in/:
  - Finish project
  - Get money in account
  - Drink a Corona
  - Read while lying in a hammock
* 3995 sets / sec individually for 100000 items in 25.03 seconds
* 171 sets / sec as batch for 100000 items in 583.13 seconds
* 2126 gets / sec individually for 100000 items in 47.04 seconds
* 14335 gets / sec as batch for 100000 items in 6.98 seconds

=end
