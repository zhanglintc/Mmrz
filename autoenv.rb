#!/env/bin/ruby
# encoding: utf-8

puts "Step1: change download server"
system "gem sources --remove https://rubygems.org/"
system "gem sources --remove https://ruby.taobao.org/"
system "gem sources --add https://gems.ruby-china.com"

puts ""
puts "Step2: install sqlite3"
system "gem install sqlite3"

puts ""
puts "Result: environment for Mmrz is OK"
puts "Press any key to close..."
gets