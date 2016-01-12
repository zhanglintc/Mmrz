#!/env/bin/ruby
# encoding: utf-8

puts "Changing remote address:"
system "gem sources --add https://ruby.taobao.org/ --remove https://rubygems.org/"

puts ""
puts "Installing sqlite3:"
system "gem install sqlite3"

puts ""
puts "Everything's OK"
puts "Press any key to close..."
gets
