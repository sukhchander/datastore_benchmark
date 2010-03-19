#!/usr/bin/env ruby

require "rubygems"

# InnoDB
system %{echo "drop database if exists test; create database test; use test; create table bench ( id INT NOT NULL AUTO_INCREMENT, PRIMARY KEY(id), number INT, message VARCHAR(64)) ENGINE=InnoDB; create unique index bench_idx on bench(number);" | mysql}

# MyISAM
# system %{echo "drop database if exists test; create database test; use test; create table bench ( id INT NOT NULL AUTO_INCREMENT, PRIMARY KEY(id), number INT, message VARCHAR(64)) ENGINE=MyISAM; create unique index bench_idx on bench(number);" | mysql}

require "dbi"
USER = "root"
PASS = ""
DSN = "DBI:Mysql:test"

dbh = DBI.connect(DSN, USER, PASS)

require 'benchmarking'
include Benchmarking

n = 100000

dbh.do "delete from bench"
sth = dbh.prepare "insert into bench (number, message) values (?, ?)"
s = elapsed do
  for i in 0...n
    sth.execute i, "foobar"
  end
end
puts "* %i sets / sec individually for %i items in %0.2f seconds" % [n/s, n, s]

dbh.do "delete from bench"
dbh.execute "begin"
sth = dbh.prepare "insert into bench (number, message) values (?, ?)"
s = elapsed do
  for i in 0...n
    sth.execute i, "foobar"
  end
end
dbh.execute "commit"
puts "* %i sets / sec as batch for %i items in %0.2f seconds" % [n/s, n, s]

sth = dbh.prepare "select * from bench where number = ?"
s = elapsed do
  for i in 0...n
    sth.execute(i)
    item = sth.fetch_hash
    item["number"].to_i == i or raise "Mismatch! Expected #{i}, got: #{item.inspect}"
  end
end
puts "* %i gets / sec individually for %i items in %0.2f seconds" % [n/s, n, s]

seen = {}
s = elapsed do
  dbh.select_all("select * from bench").each do |item|
    i = item["number"]
    if seen[i]
      raise "Already saw #{i}"
    else
      seen[i] = true
    end
  end
end
puts "* %i gets / sec as batch for %i items in %0.2f seconds" % [n/s, n, s]

system %{echo "drop database test;" | mysql}

=begin
MySQL 5.1.42 with MyISAM w/ mydbi 1.0.5 w/ ruby 1.8.7
* 6880 sets / sec individually for 10000 items in 1.45 seconds
* 6871 sets / sec as batch for 10000 items in 1.46 seconds
* 1085 gets / sec individually for 10000 items in 9.21 seconds
* 36746 gets / sec as batch for 10000 items in 0.27 seconds

MySQL 5.1.42 with InnoDB w/ mydbi 1.0.5 w/ ruby 1.8.7
* 1888 sets / sec individually for 10000 items in 5.30 seconds
* 6573 sets / sec as batch for 10000 items in 1.52 seconds
* 1078 gets / sec individually for 10000 items in 9.27 seconds
* 37941 gets / sec as batch for 10000 items in 0.26 seconds

MySQL 5.1.42 with MyISAM w/ mydbi 1.0.5 w/ ruby 1.8.7
* 6844 sets / sec individually for 100000 items in 14.61 seconds
* 6928 sets / sec as batch for 100000 items in 14.43 seconds
* 1247 gets / sec individually for 100000 items in 80.17 seconds
* 31740 gets / sec as batch for 100000 items in 3.15 seconds

MySQL 5.1.42 with InnoDB w/ mydbi 1.0.5 w/ ruby 1.8.7
* 1959 sets / sec individually for 100000 items in 51.03 seconds
* 6811 sets / sec as batch for 100000 items in 14.68 seconds
* 1243 gets / sec individually for 100000 items in 80.44 seconds
* 30325 gets / sec as batch for 100000 items in 3.30 secon
=end
