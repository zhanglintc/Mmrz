#!/env/bin/ruby
# encoding: utf-8

here = File.dirname(__FILE__)

puts "Step_1: add certificate"
system "cmd /c setx SSL_CERT_FILE #{here}/cacert.pem -m"

puts ""
puts "Step_2: change download server"
system "cmd /c gem sources --add https://ruby.taobao.org/ --remove https://rubygems.org/"

puts ""
puts "Step_3: install sqlite3"
system "cmd /c gem install sqlite3"

puts ""
puts "Result: environment for Mmrz is OK"
puts "Press any key to close..."
gets
