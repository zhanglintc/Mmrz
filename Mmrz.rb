#!/env/bin/ruby
# encoding: utf-8

require "readline"
require 'sqlite3'

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8
  
# db = SQLite3::Database.new "ummrz.db"

welcome_str = "\
Welcome to Mmrz !!! -- Memorize words easily.
Mmrz is tool help you to memorize words.
Powered by zhanglintc. [v0.1]

Available commands:
 - add:  Add words(espacilly Japanese) to word book.
 - list: List all your words in word book.
 - exit: Exit the application.
"

$mmrz_list = {} # {word => [pronounce, remindTime]}

def add_word
=begin 
    Add Japanese word and its pronunciation to database.
    TODO: add data to data base.
=end
  system "clear"
  puts "Adding mode (単語 平仮名):"
  print "Add => "

  command = STDIN.gets.chomp.gsub(/^\s*|\s*$/, "")
  while not "exit" == command
    words = command.split
    if not words.size == 2
      puts "format not correct"
      print "Add => "
      command = STDIN.gets.chomp.gsub(/^\s*|\s*$/, "")
      next
    end
    
    word, pronounce = words[0], words[1]
    $mmrz_list[word] = {:pronounce => pronounce, :remindTime => 111}

    print "Add => "
    command = STDIN.gets.chomp.gsub(/^\s*|\s*$/, "")
  end
  system "clear"
end

def list_word
  $mmrz_list.each do |k, v|
    puts "#{k}: #{v[:pronounce]}"
  end
end

if __FILE__ == $0
  system "clear"
  puts welcome_str

  while true
    print "Mmrz => "
    command = STDIN.gets.chomp.gsub(/^\s*|\s*$/, "")
    case command
    when "exit"
      exit()
    when "add"
      add_word()
    when "list"
      list_word()
    else
      puts "Mmrz: command not found"
    end
  end
end


