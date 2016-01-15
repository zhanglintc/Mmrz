#!/env/bin/ruby
# encoding: utf-8

# TODO: try use thread process instead of the mass of global variables
# TODO: add TTS options(engine select | speed select | etc.)
# TODO: use namespace

require File.dirname(__FILE__) + '/comm.rb'
require File.dirname(__FILE__) + '/db.rb'

require 'tk'
require 'sqlite3'
require 'win32ole' if WINDOWS

VERSION = "v0.1.6"
TITLE   = "Mmrz"
TTSSupport = find_misaki

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

$version_info = "\
Welcome to Mmrz !!!
Mmrz is tool help you memorizing words easily.

https://github.com/zhanglintc/Mmrz
Powered by zhanglintc. [#{VERSION}]
"
# Main window
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

# Wordbook window
$tk_wb_height = 500
$tk_wb_width  = 800

$tk_wb_list_height = $tk_wb_height - 20
$tk_wb_list_width = $tk_wb_width - 30
$tk_wb_list_x = 10
$tk_wb_list_y = 10

$tk_wb_scroll_height = $tk_wb_height - 20
$tk_wb_scroll_x = $tk_wb_width - 20
$tk_wb_scroll_y = $tk_wb_list_y

def import_file path
  if "".include? path
    return
  end

  if not path.include? ".mmz" and not path.include? ".yb"
    Tk.messageBox 'message' => "Only support \"*.mmz *.yb\" file"
    return
  end

  if path.include? ".mmz"
    suffix = ".mmz"
  elsif path.include? ".yb"
    suffix = ".yb"
  else
    suffix = ".*"
  end

  begin
    fr = open path
  rescue
    Tk.messageBox 'message' => "Open file \"#{path}\" failed"
    return
  end

  dbMgr = MmrzDBManager.new

  not_loaded_line = ""
  line_idx = 0
  no_added = 0
  added = 0
  fr.each_line do |line|
    line_idx += 1
    $tk_root.title "#{TITLE} -- Importing line #{line_idx}"
    if suffix == ".mmz"
      wordInfo = line.encode.split
      if not [2, 3].include? wordInfo.size
        not_loaded_line += "- line #{line_idx}, format error\n"
        no_added += 1
        next
      end
    end

    if suffix == ".yb"
      line.chomp.gsub!(/ /, "")
      if line =~ /(.*)「(.*)」(.*)/
        if $2 == ""
          wordInfo = [$1, $3]
        else
          wordInfo = [$1, $2, $3]
        end
      else
        not_loaded_line += "- line #{line_idx}, format error\n"
        no_added += 1
      end
    end
    
    word          = wordInfo[0]
    pronounce     = (wordInfo.size == 2 ? wordInfo[1] : "#{wordInfo[1]} -- #{wordInfo[2]}")
    memTimes      = 0
    remindTime    = cal_remind_time(memTimes, "int")
    remindTimeStr = cal_remind_time(memTimes, "str")
    wordID        = dbMgr.getMaxWordID + 1

    row = [word, pronounce, memTimes, remindTime, remindTimeStr, wordID]
    p format("loaded: %s <==> %s\n", word, pronounce)
    dbMgr.insertDB row

    added += 1
  end

  fr.close
  dbMgr.closeDB
  show_word # refresh title
  Tk.messageBox  'message' => "Import file \"#{path}\" completed\n\n#{added} words added\n#{no_added} words aborted\n\n\nNot loaded lines are shown below:\n\n#{not_loaded_line}"
end

def speak_word
  $speaker.speak $rows_from_DB[$cursor_of_rows][0] if $rows_from_DB != []
end

$tk_root = TkRoot.new do
  title TITLE # would be overrided
  minsize $tk_root_width, $tk_root_height
  maxsize $tk_root_width, $tk_root_height
end

"""
Main menu configurations.
"""
$menu_click = Proc.new {
  Tk.messageBox(
    'type'    => "ok",  
    'icon'    => "info",
    'title'   => "Coming soon",
    'message' => "Under developing"
  )
}

$make_wb_win = Proc.new do
  $tk_win_wordbook = TkToplevel.new do
    minsize $tk_wb_width, $tk_wb_height
    maxsize $tk_wb_width, $tk_wb_height
  end

  $tk_wb_list = TkListbox.new($tk_win_wordbook) do
    font TkFont.new "simsun"
    place 'width' => $tk_wb_list_width, 'height' => $tk_wb_list_height, 'x' => $tk_wb_list_x, 'y' => $tk_wb_list_y
  end

  $tk_wb_scroll = TkScrollbar.new($tk_win_wordbook) do
    orient 'vertical'
    place 'height' => $tk_wb_scroll_height, 'x' => $tk_wb_scroll_x, 'y' => $tk_wb_scroll_y
  end

  $tk_wb_list.yscrollcommand( Proc.new { |*args| $tk_wb_scroll.set(*args) } )
  $tk_wb_scroll.command( Proc.new { |*args| $tk_wb_list.yview(*args) } )

  dbMgr = MmrzDBManager.new
  rows = dbMgr.readAllDB
  $tk_win_wordbook.title = "Wordbook -- #{rows.size} words"

  tail_of_8_times = []
  rows.sort! { |r1, r2| r1[3] <=> r2[3] } # remindTime from short to long
  rows.each do |row|
    word          = row[0]
    pronounce     = row[1]
    memTimes      = row[2]
    remindTime    = row[3]
    remindTimeStr = row[4]
    wordID        = row[5]

    remindTime -= Time.now.to_i
    if remindTime > 0
      day  = remindTime / (60 * 60 * 24)
      hour = remindTime % (60 * 60 * 24) / (60 * 60)
      min  = remindTime % (60 * 60 * 24) % (60 * 60) / 60
    else
      day = hour = min = 0
    end

    if memTimes >= 8
      remindTimeStr = format("%sd-%sh-%sm", day, hour, min)
      one_word_line = format("%4d => next: %11s, %d times, %s, %s", wordID, remindTimeStr, memTimes, word, pronounce)
      tail_of_8_times << one_word_line
      next
    end

    remindTimeStr = format("%sd-%sh-%sm", day, hour, min)
    one_word_line = format("%4d => next: %11s, %d times, %s, %s", wordID, remindTimeStr, memTimes, word, pronounce)
    $tk_wb_list.insert $tk_wb_list.size, one_word_line
  end

  tail_of_8_times.each do |one_word_line|
    $tk_wb_list.insert $tk_wb_list.size, one_word_line
  end

  dbMgr.closeDB
end

$file_menu = TkMenu.new($tk_root)
$file_menu.add( 'command',
                'label'     => "Import",
                'command'   => Proc.new { Thread.start do import_file Tk.getOpenFile 'filetypes' => "{MMZ {.mmz}} {YB {.yb}} {ALL {.*}}" end },
                'underline' => 0)
$file_menu.add( 'command',
                'label'     => "Export",
                'command'   => $menu_click,
                'underline' => 0)
$file_menu.add( 'separator' )
$file_menu.add( 'command',
                'label'     => "Exit",
                'command'   => Proc.new {exit},
                'underline' => 1)

$edit_menu = TkMenu.new($tk_root)
$edit_menu.add( 'command',
                'label'     => "Pass",
                'command'   => Proc.new { 
                                hide_secret false, true
                                show_word
                                $tk_show.place 'height' => $tk_show_height, 'width' => $tk_show_width, 'x' => $tk_show_x, 'y' => $tk_show_y
                                $tk_yes.unplace
                                $tk_no.unplace
                              },
                'underline' => 0)
$edit_menu.add( 'separator' )
$edit_menu.add( 'command',
                'label'     => "Setting",
                'command'   => $menu_click,
                'underline' => 0)

$view_menu = TkMenu.new($tk_root)
$view_menu.add( 'command',
                'label'     => "Wordbook",
                'command'   => $make_wb_win,
                'underline' => 0)

$help_menu = TkMenu.new($tk_root)
$help_menu.add( 'command',
                'label'     => "Usage",
                'command'   => $menu_click,
                'underline' => 0)
$help_menu.add( 'command',
                'label'     => "About",
                'underline' => 0,
                'command'   => Proc.new {
                  Tk.messageBox(
                    'type'    => "ok",  
                    'icon'    => "info",
                    'title'   => "About",
                    'message' => $version_info)}
              )

$menu_bar = TkMenu.new
$menu_bar.add('cascade',
              'menu'  => $file_menu,
              'label' => "File",
              'underline' => 0)
$menu_bar.add('cascade',
              'menu'  => $edit_menu,
              'label' => "Edit",
              'underline' => 0)
$menu_bar.add('cascade',
              'menu'  => $view_menu,
              'label' => "View",
              'underline' => 0)
$menu_bar.add('command',
              'command'   => Proc.new { speak_word },
              'label'     => "Speak",
              'underline' => 0) if TTSSupport
              
$menu_bar.add('cascade',
              'menu'  => $help_menu,
              'label' => "Help",
              'underline' => 0)
$tk_root.menu($menu_bar)


"""
Main window configurations, label, button, etc.
"""
$tk_word = TkLabel.new $tk_root do
  borderwidth 0
  font TkFont.new 'simsun 20 bold'
  foreground "black"
  relief "groove"
  place 'height' => $tk_word_height, 'width' => $tk_word_width, 'x' => $tk_word_x, 'y' => $tk_word_y
end

$tk_pronounce = TkLabel.new $tk_root do
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
    hide_secret true, false
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
    hide_secret false, false
    show_word
    $tk_show.place 'height' => $tk_show_height, 'width' => $tk_show_width, 'x' => $tk_show_x, 'y' => $tk_show_y
    $tk_yes.unplace
    $tk_no.unplace
  end
end

"""
Main functions.
"""
def move_cursor
  if $cursor_of_rows == $rows_from_DB.size
    $cursor_of_rows = 0
    return
  end

  $cursor_of_rows += 1
  $cursor_of_rows = 0 if $cursor_of_rows == $rows_from_DB.size
end

def show_word
  if $rows_from_DB.size == 0
    $tk_root.title "#{TITLE} -- #{get_shortest_remind}"
    $tk_word.text "本次背诵完毕"
    $tk_exit.place 'height' => $tk_show_height, 'width' => $tk_show_width, 'x' => $tk_show_x, 'y' => $tk_show_y
  else
    $tk_word.text $rows_from_DB[$cursor_of_rows][0]
    $tk_root.title "#{TITLE} -- #{$rows_from_DB.size} words left"
  end
end

def show_secret
  $tk_pronounce.text $rows_from_DB[$cursor_of_rows][1]
end

def hide_secret remember, pass
  if $rows_from_DB.empty?
    Tk.messageBox 'message' => "No word specified"
    return
  end

  if remember or pass
    row = $rows_from_DB[$cursor_of_rows]
    firstTimeFail = row[6]
    row[2] += 1 if not firstTimeFail
    row[2] = 8 if pass
    row[3] = cal_remind_time row[2], "int"
    row[4] = cal_remind_time row[2], "str"

    # use thread to avoid UI refresh lagging
    Thread.start do
      sleep 0.01 # sleep some seconds to avoid updateDB and refresh UI at same time
      dbMgr = MmrzDBManager.new
      dbMgr.updateDB row
      dbMgr.closeDB
    end

    $rows_from_DB.delete_at $cursor_of_rows
  else
    $rows_from_DB[$cursor_of_rows][6] = true # firstTimeFail: false => true
  end
  move_cursor
  $tk_pronounce.text ""
end

"""
Entry point
"""
if __FILE__ == $0
  dbMgr = MmrzDBManager.new
  dbMgr.createDB
  dbMgr.closeDB

  dbMgr = MmrzDBManager.new
  $rows_from_DB = []
  dbMgr.readDB.each do |row|
    # [0~5]read from DB, [6]new added firstTimeFail
    row[6] = false # initialize firstTimeFail as false
    $rows_from_DB << row if row[3] < Time.now.to_i
  end
  $cursor_of_rows = 0
  dbMgr.closeDB

  show_word
  Tk.mainloop
end


