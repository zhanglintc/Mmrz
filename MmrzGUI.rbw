#!/env/bin/ruby
# encoding: utf-8

require 'tk'
require 'sqlite3'
require File.dirname(__FILE__) + '/db.rb'

# TODO: 增加 Menu 栏

Version = "v0.1.0"
Title   = "Mmrz"

$tk_root_height = 230
$tk_root_width = 400

$tk_word_x = 10
$tk_word_y = 30
$tk_word_height = 50
$tk_word_width  = $tk_root_width - ($tk_word_x * 2)

$tk_pronounce_x = 10
$tk_pronounce_y = 80
$tk_pronounce_height = 50
$tk_pronounce_width  = $tk_root_width - ($tk_pronounce_x * 2)

$tk_show_height = 50
$tk_show_width  = 100
$tk_show_x = ($tk_root_width - $tk_show_width) / 2
$tk_show_y = 90

$tk_yes_height = 50
$tk_yes_width  = 100
$tk_yes_x = 60
$tk_yes_y = 150

$tk_no_height = 50
$tk_no_width  = 100
$tk_no_x = $tk_root_width - $tk_no_width - $tk_yes_x
$tk_no_y = 150

def cal_remind_time memTimes, type
  curTime = Time.now

  case memTimes
  when 0
    remindTime = curTime + (60 * 5) # 5 minuts
    # remindTime = curTime # 0 minuts, debug mode
  when 1
    remindTime = curTime + (60 * 30) # 30 minuts
  when 2
    remindTime = curTime + (60 * 60 * 12) # 12 hours
  when 3
    remindTime = curTime + (60 * 60 * 24) # 1 day
  when 4
    remindTime = curTime + (60 * 30 * 24 * 2) # 2 days
  when 5
    remindTime = curTime + (60 * 30 * 24 * 4) # 4 days
  when 6
    remindTime = curTime + (60 * 30 * 24 * 7) # 7 days
  when 7
    remindTime = curTime + (60 * 30 * 24 * 15) # 15 days
  else
    remindTime = curTime
  end

  case type
  when "int"
    return remindTime.to_i
  when "str"
    return remindTime.to_s[0..-7]
  end
end

$root = TkRoot.new do
  title Title
  minsize $tk_root_width, $tk_root_height
  maxsize $tk_root_width, $tk_root_height
end

$tk_word = TkLabel.new $root do
  borderwidth 0
  font TkFont.new 'simsun 20 bold'
  foreground "black"
  relief "groove"
  place 'height' => $tk_word_height, 'width' => $tk_word_width, 'x' => $tk_word_x, 'y' => $tk_word_y
end

$tk_pronounce = TkLabel.new $root do
  borderwidth 0
  font TkFont.new 'simsun 15'
  foreground "black"
  relief "groove"
  place 'height' => $tk_pronounce_height, 'width' => $tk_pronounce_width, 'x' => $tk_pronounce_x, 'y' => $tk_pronounce_y
end

$tk_show = TkButton.new do
  text '查看'
  background "yellow"
  foreground "blue"
  place 'height' => $tk_show_height, 'width' => $tk_show_width, 'x' => $tk_show_x, 'y' => $tk_show_y
  command do
    show_secret
    unplace
    $tk_yes.place 'height' => $tk_yes_height,'width' => $tk_yes_width,'x' => $tk_yes_x,'y' => $tk_yes_y
    $tk_no.place 'height' => $tk_no_height, 'width' => $tk_no_width, 'x' => $tk_no_x, 'y' => $tk_no_y
  end
end

$tk_exit = TkButton.new do
  text '退出'
  background "yellow"
  foreground "blue"
  command do
    exit
  end
end

$tk_yes = TkButton.new do
  text '记得住'
  background "yellow"
  foreground "blue"
  command do
    hide_secret true
    show_word
    $tk_show.place 'height' => $tk_show_height, 'width' => $tk_show_width, 'x' => $tk_show_x, 'y' => $tk_show_y
    $tk_yes.unplace
    $tk_no.unplace
  end
end

$tk_no = TkButton.new do
  text '记不住'
  background "yellow"
  foreground "blue"
  command do
    hide_secret false
    show_word
    $tk_show.place 'height' => $tk_show_height, 'width' => $tk_show_width, 'x' => $tk_show_x, 'y' => $tk_show_y
    $tk_yes.unplace
    $tk_no.unplace
  end
end

def move_cursor
  $cursor += 1
  $cursor = 0 if $cursor == $rows.size
end

def show_word
  if $rows.size == 0
    $root.title "#{Title} -- Powered by zhanglintc"
    $tk_word.text "本次背诵完毕"
    $tk_exit.place 'height' => $tk_show_height, 'width' => $tk_show_width, 'x' => $tk_show_x, 'y' => $tk_show_y
  else
    $tk_word.text $rows[$cursor][0]
    $root.title "#{Title} -- #{$rows.size} words left"
  end
end

def show_secret
  $tk_pronounce.text $rows[$cursor][1]
end

def hide_secret remember
  if remember
    row = $rows[$cursor]
    row[2] += 1
    row[3] = cal_remind_time row[2], "int"
    row[4] = cal_remind_time row[2], "str"

    dbMgr = MmrzDBManager.new
    dbMgr.updateDB row
    dbMgr.closeDB

    $rows.delete_at $cursor
  else
    move_cursor
  end
  $tk_pronounce.text ""
end

dbMgr = MmrzDBManager.new
dbMgr.createDB
dbMgr.closeDB

dbMgr = MmrzDBManager.new
$rows = []
dbMgr.readDB.each do |row|
  $rows << row if row[3] < Time.now.to_i
end
$cursor = 0
dbMgr.closeDB

show_word
Tk.mainloop


