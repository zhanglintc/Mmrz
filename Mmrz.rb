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

def my_readline prompt
=begin 
  Get user's input with CR||LF and front||end spaces removed.
=end
  Readline.readline(prompt, true).chomp.gsub(/^\s*|\s*$/, "")
end

def add_word
=begin 
    Add Japanese word and its pronunciation to database.
    TODO: add data to data base.
=end
  system "clear"
  puts "Adding mode (word pronunciation):"

  while not "exit" == ( command = my_readline("Add => ") )
    words = command.split
    if not words.size == 2
      puts "Add: format not correct"
      next
    end
    
    word, pronounce = words[0], words[1]
    $mmrz_list[word] = {:pronounce => pronounce, :remindTime => 111}
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
    command = my_readline("Mmrz => ")
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


