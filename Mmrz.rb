#!/env/bin/ruby
# encoding: utf-8

require 'rubygems'
require 'readline'
require 'sqlite3'
require 'rbconfig'
require 'io/console'
require './db.rb'

# Encoding.default_external = Encoding::UTF_8
# Encoding.default_internal = Encoding::UTF_8

welcome_str = "\
Welcome to Mmrz !!! -- Memorize words easily.
Mmrz is tool help you to memorize words.
Powered by zhanglintc. [v0.1]

Available commands:
 - add:  Add words(espacilly Japanese) to word book.
 - list: List all your words in word book.
 - mmrz:  Memorize words.
 - exit: Exit the application.
 \
"

def my_readline prompt
  # Get user's input with CR||LF and front||end spaces removed.
  Readline.readline(prompt, true).chomp.gsub(/^\s*|\s*$/, "")
end

def clear_sreen
  # Windows
  if RbConfig::CONFIG['target_os'] == "mingw32"
    system "cls"
  # Linux/Mac
  else
    system "clear"
  end
end

def pause
  # Windows
  if RbConfig::CONFIG['target_os'] == "mingw32"
    system "pause>nul"
  # Linux/Mac
  else
    STDIN.getch
  end
end

def cal_remind_time memTimes
  curTime = Time.now.to_i

  case memTimes
  when 0
    return curTime + (60 * 5) # 5 minuts
  when 1
    return curTime + (60 * 30) # 30 minuts
  when 2
    return curTime + (60 * 60 * 12) # 12 hours
  when 3
    return curTime + (60 * 60 * 24) # 1 day
  when 4
    return curTime + (60 * 30 * 24 * 2) # 2 days
  when 5
    return curTime + (60 * 30 * 24 * 4) # 4 days
  when 6
    return curTime + (60 * 30 * 24 * 7) # 7 days
  when 7
    return curTime + (60 * 30 * 24 * 15) # 15 days
  end
    
end

def add_word
  dbMgr = MmrzDBManager.new
  clear_sreen()
  puts "Adding mode:"

  while not "exit" == ( command = my_readline("Add => ") )
    words = command.split
    if not words.size == 2
      puts "\nAdd: format not correct"
      next
    end
    
    word       = words[0]
    pronounce  = words[1]
    memTimes   = 0
    remindTime = cal_remind_time(memTimes)
    
    row = [word, pronounce, memTimes, remindTime]
    dbMgr.insertDB row 
  end

  dbMgr.closeDB 
  clear_sreen()
end

def list_word
  dbMgr = MmrzDBManager.new
  dbMgr.readDB.each {|row| p row}
  dbMgr.closeDB
end

def mmrz_word
  dbMgr = MmrzDBManager.new
  read_rows  = dbMgr.readDB

  # select words that need to be memorized
  selected_rows = {} # { list: row_as_key => boolean: remembered }
  read_rows.each do |r|
    selected_rows[r] = false if r[3] < Time.now.to_i
  end

  left_words = selected_rows.size
  if left_words == 0
    clear_sreen()
    puts "No word need to be memorized...\n\n"
    return
  end

  # memorize!!!
  while true
    completed = true
    selected_rows.each do |row_as_key, remembered|
      if not remembered
        # TODO: delete? words after 8 times memorize
        # TODO: do not update memTimes if not remembered at first choose
        clear_sreen()
        puts "Memorize mode:\n\n"
        puts "[#{left_words}] #{ left_words == 1 ? 'word' : 'words'} left:\n\n"
        puts "単語: #{row_as_key[0]}"
        puts "-------------------"
        print "発音: "
        pause
        puts "#{row_as_key[1]}\n\n"
        command = my_readline("Do you remember => ")

        if command == "yes"
          # mark remembered as true
          selected_rows[row_as_key] = true
          left_words -= 1

          # after "mark remembered as true", row_as_key can be changed
          # update database
          row_as_key[2] += 1
          row_as_key[3] = cal_remind_time(row_as_key[2])
          dbMgr.updateDB row_as_key
        elsif command == "exit"
          clear_sreen()
          return
        else
          completed = false
        end
      end
    end

    break if completed
  end

  clear_sreen()
  puts "Memorize completed...\n\n"
  dbMgr.closeDB
end

if __FILE__ == $0
  dbMgr = MmrzDBManager.new
  dbMgr.createDB
  dbMgr.closeDB

  clear_sreen()
  puts welcome_str

  while true
    command = my_readline("Mmrz => ")
    case command
    when "exit"
      exit()
    when "add"
      add_word
    when "list"
      list_word()
    when "mmrz"
      mmrz_word()
    else
      puts "\nMmrz: command not found"
    end
  end
end

