#!/env/bin/ruby
# encoding: utf-8

# TO nerver DO: try to use Class(singleton) to handle the mass of global variables
# TO nerver DO: add TTS options(engine select | speed select | etc.)
# TO nerver DO: use namespace

require File.dirname(__FILE__) + '/comm.rb'
require File.dirname(__FILE__) + '/db.rb'
require File.dirname(__FILE__) + '/sync.rb'

require 'tk'
require 'net/http'
require 'fileutils'
require 'json'
require 'base64'
require 'win32ole' if COMM::PLATFORM_WINDOWS

TITLE   = COMM::REVERSE_MODE ? "Mmrz[R]" : "Mmrz"
VERSION = "GUI-0.2.6"
FAVICON = "./misc/fav.ico"

TTSSupport   = (COMM::USE_TTS_ENGINE and (COMM::PLATFORM_WINDOWS ? COMM::find_misaki? : true))
$tts_speaker = (COMM::make_speaker if TTSSupport)

# this variable is only used when user has changed settings
$secret_is_hiding = true

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

$version_info = "\
Welcome to Mmrz !!!
Mmrz is a tool help you memorizing words easily.

https://github.com/zhanglintc/Mmrz
Powered by zhanglintc. [#{VERSION}]
"

def make_size
  # Main window
  $tk_root_width = COMM::MAIN_WIN_WIDTH
  $tk_root_height = COMM::MAIN_WIN_HEIGHT

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
  $tk_yes_x = $tk_root_width / 2 - ($tk_yes_width + 40)
  $tk_yes_y = 150

  $tk_no_height = 50
  $tk_no_width  = 100
  $tk_no_x = $tk_root_width - $tk_no_width - $tk_yes_x
  $tk_no_y = 150

  # Wordbook window
  $tk_wb_width  = COMM::WB_WIN_WIDTH
  $tk_wb_height = COMM::WB_WIN_HEIGHT

  $tk_wb_list_height = $tk_wb_height - 20
  $tk_wb_list_width = $tk_wb_width - 30
  $tk_wb_list_x = 10
  $tk_wb_list_y = 10

  $tk_wb_scroll_height = $tk_wb_height - 20
  $tk_wb_scroll_x = $tk_wb_width - 20
  $tk_wb_scroll_y = $tk_wb_list_y
end

"""
Main window configurations, label, button, etc.
"""
$tk_root = TkRoot.new
$tk_word = TkLabel.new $tk_root
$tk_pronounce = TkLabel.new $tk_root
$tk_show = TkButton.new
$tk_exit = TkButton.new
$tk_yes = TkButton.new
$tk_no = TkButton.new

def show_about
  ms = MmrzSync.new
  remote_ver = ms.get_remote_version
  if remote_ver and ms.version_to_int(VERSION) < ms.version_to_int(remote_ver)
    info = $version_info + "\nNote: new version [#{remote_ver}] available"
  else
    remote_ver = "unknown" if remote_ver == nil
    info = $version_info + "\nNewest version: [#{remote_ver}]"
  end

  return info
end

def check_update
  Thread.start do
    ms = MmrzSync.new
    remote_ver = ms.get_remote_version

    if ms.version_to_int(VERSION) < ms.version_to_int(remote_ver)
      Tk.messageBox( 
        'title'   => "Checking for update",
        'message' => "New version [#{remote_ver}] available\nLocal version: [#{VERSION}]\n\nPlease use \"SVN update\" to get latest version"
      )
    end
  end
end

def urlencode params
  URI.escape(params.collect{|k, v| "#{k}=#{v}"}.join('&'))
end

def pull_wordbook
  username = $tk_username.get.encode("utf-8")
  password = $tk_password.get.encode("utf-8")

  if username == "" or password == ""
    $tk_win_pull_push.messageBox 'message' => "账户和密码均不能为空!!!"
    $tk_win_pull_push.focus
    return
  end

  params = {
    'username' => username,
    'password' => Base64.strict_encode64(password),
  }

  uri = URI("#{COMM::SERVERADDR}/download_wordbook/?" + urlencode(params))
  received = JSON.parse Net::HTTP.get(uri)

  verified = received['verified']
  if not verified
    $tk_win_pull_push.messageBox 'message' => "账户或密码错误, 登录失败"
    $tk_win_pull_push.focus
    return
  end
  
  rows = received['wordbook']

  wordbook_bak = "#{File.dirname(__FILE__)}/wordbook_#{Time.now.strftime("%Y%m%d%H%M%S")}.bak"
  FileUtils.cp("#{File.dirname(__FILE__)}/wordbook.db", wordbook_bak)

  dbMgr = MmrzDBManager.new
  dbMgr.pruneDB
  rows.each do |row|
    dbMgr.insertDB row
  end
  dbMgr.closeDB

  $tk_win_pull_push.messageBox 'message' => "下载成功, 原单词本已备份为\"#{wordbook_bak}\"\n\n注意: 请重启本程序读取最新背诵进度"
  $tk_win_pull_push.focus
end

def sign_up
  username     = $tk_signup_username.get.encode("utf-8")
  password_1st = $tk_signup_password_1st.get.encode("utf-8")
  password_2nd = $tk_signup_password_2nd.get.encode("utf-8")

  if username == "" or password_1st == ""
    $tk_win_sign_up.messageBox 'message' => "账户和密码均不能为空!!!"
    $tk_win_sign_up.focus
    return
  end

  if password_1st != password_2nd
    $tk_win_sign_up.messageBox 'message' => "两次密码不一致, 请确认!"
    $tk_win_sign_up.focus
    return
  end

  uri = URI("#{COMM::SERVERADDR}/sign_up/?")
  post_data = {"username" => username, "password" => Base64.strict_encode64(password_1st)}
  resp = Net::HTTP.post_form(uri, post_data)
  body = JSON.parse resp.body
  
  verified = body['verified']
  if verified
    $tk_win_sign_up.messageBox 'title' => "成功", 'message' => "恭喜帐号\"#{username}\"注册成功, 请妥善保管"
  else
    $tk_win_sign_up.messageBox 'title' => "失败", 'message' => "帐号\"#{username}\"已被占用, 请修改后重试!!!"
  end
  $tk_win_sign_up.focus
end

def make_win_sign_up
  # TkRoot.messageBox 'title' => "WARNING", 'message' => "测试阶段, 请务必慎重使用! 单词本多做备份!"

  frame_width  = 210
  frame_height = 140

  $tk_win_sign_up = TkToplevel.new do
    title "注册帐号"
    iconbitmap FAVICON
    minsize frame_width, frame_height
    maxsize frame_width, frame_height
  end

  tk_username_frame = TkFrame.new($tk_win_sign_up) do
    padx 10
    pady 5
    pack 'side' => 'top', 'fill' => 'x'
  end

  TkLabel.new(tk_username_frame) do
    text "帐号："
    pack 'side' => 'left'
  end

  $tk_signup_username = TkEntry.new(tk_username_frame) do
    pack 'side' => 'left', 'fill' => 'x'
  end

  tk_password_1st_frame = TkFrame.new($tk_win_sign_up) do
    padx 10
    pady 5
    pack 'side' => 'top', 'fill' => 'x'
  end

  TkLabel.new(tk_password_1st_frame) do
    text "密码："
    pack 'side' => 'left'
  end

  $tk_signup_password_1st = TkEntry.new(tk_password_1st_frame) do
    show '*'
    pack 'side' => 'left', 'fill' => 'x'
  end

  tk_password_2nd_frame = TkFrame.new($tk_win_sign_up) do
    padx 10
    pady 5
    pack 'side' => 'top', 'fill' => 'x'
  end

  TkLabel.new(tk_password_2nd_frame) do
    text "确认："
    pack 'side' => 'left'
  end

  $tk_signup_password_2nd = TkEntry.new(tk_password_2nd_frame) do
    show '*'
    pack 'side' => 'left', 'fill' => 'x'
  end

  tk_yes_no_frame = TkFrame.new($tk_win_sign_up) do
    padx 10
    pady 5
    pack 'side' => 'top', 'fill' => 'x'
  end

  TkButton.new(tk_yes_no_frame) do
    text "关闭"
    command Proc.new { $tk_win_sign_up.destroy }
    pack 'side' => 'right', 'padx' => '5'
  end

  TkButton.new(tk_yes_no_frame) do
    text "注册"
    command Proc.new { sign_up }
    pack 'side' => 'right', 'padx' => '5'
  end
end

def push_wordbook
  username = $tk_username.get.encode("utf-8")
  password = $tk_password.get.encode("utf-8")

  if username == "" or password == ""
    $tk_win_pull_push.messageBox 'message' => "账户和密码均不能为空!!!"
    $tk_win_pull_push.focus
    return
  end

  uri = URI("#{COMM::SERVERADDR}/log_in/?")
  post_data = {"username" => username, "password" => Base64.strict_encode64(password)}
  resp = Net::HTTP.post_form(uri, post_data)
  body = JSON.parse resp.body

  verified = body['verified']
  if not verified
    $tk_win_pull_push.messageBox 'message' => "账户或密码错误, 登录失败"
  else
    dbMgr = MmrzDBManager.new
    rows_all = dbMgr.readAllDB
    dbMgr.closeDB

    uri = URI("#{COMM::SERVERADDR}/upload_wordbook/?")
    post_data = {"username" => username, "password" => Base64.strict_encode64(password), "wordbook" => rows_all.to_json}
    resp = Net::HTTP.post_form(uri, post_data)
    body = JSON.parse resp.body

    verified = body['verified']
    if verified
      $tk_win_pull_push.messageBox 'message' => "上传成功!"
    else
      $tk_win_pull_push.messageBox 'message' => "账户或密码错误, 登录失败"
    end
  end
  $tk_win_pull_push.focus
end

def make_win_pull_push type
  # TkRoot.messageBox 'title' => "WARNING", 'message' => "测试阶段, 请务必慎重使用! 单词本多做备份!"

  frame_width  = 210
  frame_height = 110

  $tk_win_pull_push = TkToplevel.new do
    if type == "pull"
      title "下载单词本"
    end
    if type == "push"
      title "上传单词本"
    end
    iconbitmap FAVICON
    # attributes 'topmost' => true
    minsize frame_width, frame_height
    maxsize frame_width, frame_height
  end

  tk_username_frame = TkFrame.new($tk_win_pull_push) do
    padx 10
    pady 5
    pack 'side' => 'top', 'fill' => 'x'
  end

  TkLabel.new(tk_username_frame) do
    text "帐号："
    pack 'side' => 'left'
  end

  $tk_username = TkEntry.new(tk_username_frame) do
    pack 'side' => 'left', 'fill' => 'x'
  end

  tk_password_frame = TkFrame.new($tk_win_pull_push) do
    padx 10
    pady 5
    pack 'side' => 'top', 'fill' => 'x'
  end

  TkLabel.new(tk_password_frame) do
    text "密码："
    pack 'side' => 'left'
  end

  $tk_password = TkEntry.new(tk_password_frame) do
    show '*'
    pack 'side' => 'left', 'fill' => 'x'
  end

  tk_yes_no_frame = TkFrame.new($tk_win_pull_push) do
    padx 10
    pady 5
    pack 'side' => 'top', 'fill' => 'x'
  end

  TkButton.new(tk_yes_no_frame) do
    text "关闭"
    command Proc.new { $tk_win_pull_push.destroy }
    pack 'side' => 'right', 'padx' => '5'
  end

  TkButton.new(tk_yes_no_frame) do
    if type == "pull"
      text "下载"
      command Proc.new { pull_wordbook }
    end
    if type == "push"
      text "上传"
      command Proc.new { push_wordbook }
    end
    pack 'side' => 'right', 'padx' => '5'
  end
end

def add_word
  word = $tk_add_word.get.encode("utf-8")
  pron = $tk_add_pron.get.encode("utf-8")
  mean = $tk_add_mean.get.encode("utf-8")

  if word == ""
    $tk_win_add.messageBox 'message' => "单词不可为空!"
    $tk_win_add.focus
    return
  end

  if pron == "" and mean == ""
    $tk_win_add.messageBox 'message' => "发音与解释不可同时为空!"
    $tk_win_add.focus
    return
  end

  dbMgr = MmrzDBManager.new

  wordInfo = []
  wordInfo << word if not word == ""
  wordInfo << pron if not pron == ""
  wordInfo << mean if not mean == ""

  word          = wordInfo[0]
  pronounce     = (wordInfo.size == 2 ? wordInfo[1] : "#{wordInfo[1]} -- #{wordInfo[2]}")
  memTimes      = 0
  remindTime    = COMM::cal_remind_time(memTimes, "int")
  remindTimeStr = COMM::cal_remind_time(memTimes, "str")
  wordID        = dbMgr.getMaxWordID + 1

  row = [word, pronounce, memTimes, remindTime, remindTimeStr, wordID]
  dbMgr.insertDB row
  dbMgr.closeDB

  $tk_win_add.title "成功添加单词: \"#{word}\""

  $tk_add_word.value = ""
  $tk_add_pron.value = ""
  $tk_add_mean.value = ""
end

def make_win_account
  frame_width  = 240
  frame_height = 150

  account_label_x = 30
  account_label_y = 10

  accout_text_x = account_label_x + 80
  accout_text_y = account_label_y

  lock_label_x = account_label_x
  lock_label_y = account_label_y + 20

  lock_text_x = lock_label_x + 80
  lock_text_y = lock_label_y

  $tk_win_account = TkToplevel.new do
    title "Account info"
    iconbitmap FAVICON
    # attributes 'topmost' => true
    minsize frame_width, frame_height
    maxsize frame_width, frame_height
  end

  $tk_acct_account_label = TkLabel.new($tk_win_account) do
    text "Account:"
    place 'x' => account_label_x, 'y' => account_label_y
  end

  $tk_acct_account_text = TkLabel.new($tk_win_account) do
    text "zhanglin"
    place 'x' => accout_text_x, 'y' => accout_text_y
  end

  $tk_acct_lock_label = TkLabel.new($tk_win_account) do
    text "Locked:"
    place 'x' => lock_label_x, 'y' => lock_label_y
  end

  $tk_acct_lock_text = TkLabel.new($tk_win_account) do
    text "Yes"
    foreground "dark green"
    place 'x' => lock_text_x, 'y' => lock_text_y
  end
end

def make_win_add
  frame_width  = 350
  frame_height = 230

  word_label_x = 10
  word_label_y = 10

  word_x = word_label_x
  word_y = word_label_y + 20
  word_width = frame_width - word_x * 2

  pron_label_x = word_x
  pron_label_y = word_y + 40

  pron_x = pron_label_x
  pron_y = pron_label_y + 20
  pron_width = frame_width - pron_x * 2

  mean_label_x = pron_x
  mean_label_y = pron_y + 40

  mean_x = mean_label_x
  mean_y = mean_label_y + 20
  mean_width = frame_width - mean_x * 2

  close_width = 60
  close_x = frame_width - 10 - close_width
  close_y = mean_y + 35

  save_width = 60
  save_x = close_x - 35 - save_width
  save_y = close_y

  $tk_win_add = TkToplevel.new do
    title "添加单个单词"
    iconbitmap FAVICON
    # attributes 'topmost' => true
    minsize frame_width, frame_height
    maxsize frame_width, frame_height
  end

  $tk_add_word_label = TkLabel.new($tk_win_add) do
    text "单词:"
    place 'x' => word_label_x, 'y' => word_label_y
  end

  $tk_add_word = TkEntry.new($tk_win_add) do
    place 'width' => word_width, 'x' => word_x, 'y' => word_y
  end

  $tk_add_pron_label = TkLabel.new($tk_win_add) do
    text "发音(可选):"
    place 'x' => pron_label_x, 'y' => pron_label_y
  end

  $tk_add_pron = TkEntry.new($tk_win_add) do
    place 'width' => pron_width, 'x' => pron_x, 'y' => pron_y
  end

  $tk_add_mean_label = TkLabel.new($tk_win_add) do
    text "解释:(可选)"
    place 'x' => mean_label_x, 'y' => mean_label_y
  end

  $tk_add_mean = TkEntry.new($tk_win_add) do
    place 'width' => mean_width, 'x' => mean_x, 'y' => mean_y
  end

  $tk_add_save = TkButton.new($tk_win_add) do
    text "Save"
    place 'width' => save_width, 'x' => save_x, 'y' => save_y
    command Proc.new { add_word }
  end

  $tk_add_close = TkButton.new($tk_win_add) do
    text "Close"
    place 'width' => close_width, 'x' => close_x, 'y' => close_y
    command Proc.new { $tk_win_add.destroy }
  end
end

def smart_import path
  # split & count lines
  fr = open path, "r"
  content = fr.read
  fr.close
  content_list = content.split("\n")
  line_quantity = content_list.size

  # get rand indexes & extract lines
  idx_range = COMM::RANDOM_PICK_UP ? line_quantity : COMM::IMPORT_QUANTITY
  idx_amount = [line_quantity, COMM::IMPORT_QUANTITY].min
  rand_idxes = []
  extracted = ""
  while rand_idxes.size != idx_amount do
    rand_num = rand 1..line_quantity
    if not rand_idxes.include? rand_num
      extracted += content_list[rand_num - 1] + "\n"
      content_list[rand_num - 1] = ""

      rand_idxes << rand_num
    end
  end

  # write back
  fw = open path, "w"
  content_list.each { |line| fw.puts line + "\n" if line != "" }
  fw.close

  return extracted
end

def import_file path
  $tk_root.title "#{TITLE} -- Preparing..."

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
    content = fr.read
    fr.close
  rescue
    Tk.messageBox 'message' => "Open file \"#{path}\" failed"
    return
  end

  content = smart_import path if COMM::SMART_IMPORT

  dbMgr = MmrzDBManager.new

  not_loaded_line = ""
  err_log_line = ""
  line_idx = 0
  no_added = 0
  added = 0
  content.each_line do |line|
    line.chomp!

    $tk_root.title "#{TITLE} -- Importing line #{line_idx}"
    line_idx += 1

    if /^[ |\t]*#.*/ =~ line or line == ""
      next # ignore comment line or null line
    end

    if suffix == ".mmz"
      wordInfo = line.encode.split
      if not [2, 3].include? wordInfo.size
        word      = wordInfo[0]
        pronounce = (wordInfo.size == 2 ? wordInfo[1] : "#{wordInfo[1]} -- #{wordInfo[2]}")
        err = format("not loaded: %s <==> %s\n", word, pronounce)
        not_loaded_line += "- line #{line_idx}: format error\n"
        err_log_line += "- line #{line_idx}: #{line}\n"
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
        word      = wordInfo[0]
        pronounce = (wordInfo.size == 2 ? wordInfo[1] : "#{wordInfo[1]} -- #{wordInfo[2]}")
        err = format("not loaded: %s <==> %s\n", word, pronounce)
        not_loaded_line += "- line #{line_idx}: format error\n"
        err_log_line += "- line #{line_idx}: #{line}\n"
        no_added += 1
        next
      end
    end
    
    word          = wordInfo[0]
    pronounce     = (wordInfo.size == 2 ? wordInfo[1] : "#{wordInfo[1]} -- #{wordInfo[2]}")
    memTimes      = 0
    remindTime    = COMM::cal_remind_time(memTimes, "int")
    remindTimeStr = COMM::cal_remind_time(memTimes, "str")
    wordID        = dbMgr.getMaxWordID + 1

    row = [word, pronounce, memTimes, remindTime, remindTimeStr, wordID]
    p format("loaded: %s <==> %s\n", word, pronounce)
    dbMgr.insertDB row

    added += 1
  end

  ferr = open "import.log", "a"
  ferr.puts Time.now
  ferr.puts err_log_line
  ferr.puts ""
  ferr.close

  dbMgr.closeDB
  show_word # refresh title
  Tk.messageBox  'message' => "Import file \"#{path}\" completed\n\n#{added} words added\n#{no_added} #{no_added < 2 ? 'word' : 'words'} aborted\n\n\nNot loaded lines are shown below.\nSee \"import.log\" for details:\n\n#{not_loaded_line}"
end

def export_to_file
  export_file = Tk.getSaveFile 'filetypes' => "{MMZ {.mmz}} {ALL {.*}}", 'initialfile' => "export", 'defaultextension' => ".mmz"
  return if export_file == ""

  idx = 0
  to_be_written = ""

  dbMgr = MmrzDBManager.new
  rows = dbMgr.readAllDB
  dbMgr.closeDB

  rows.each do |row|
    idx += 1
    word = pronounce = meaning = ""
    if row[1].gsub(/ /, "") =~ /(.*)--(.*)/
      word      = row[0]
      pronounce = $1
      meaning   = $2
    else
      word      = row[0]
      pronounce = row[1]
    end
    to_be_written += "#{word}  #{pronounce}  #{meaning}\r\n"
  end

  fw = open export_file, "wb"
  fw.write to_be_written
  fw.close
  Tk.messageBox 'message' => "Exported #{idx} words to \"#{File.basename export_file}\" success"
end

def speak_word
  # speaker.speak( text, syncType )
  $tts_speaker.speak $rows_from_DB[$cursor_of_rows][0], 1 if $rows_from_DB != []
end

def edit_setting
  if COMM::get_OS == "mac"
    `open -a TextEdit #{ConfigManager.User_setting_path}`
    Thread.start do
      while `pgrep -f TextEdit` != "" do end
      ConfigManager.new.refresh
    end
  elsif COMM::get_OS == "win"
    system "notepad #{ConfigManager.User_setting_path}"
    ConfigManager.new.refresh
  else
    puts "Not supported!"
  end
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
    iconbitmap FAVICON
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
    day, hour, min, sec = COMM::split_remindTime remindTime, true

    if memTimes >= COMM::MAX_MEM_TIMES
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
                'command'   => Proc.new { export_to_file },
                'underline' => 0)
$file_menu.add( 'separator' )
$file_menu.add( 'command',
                'label'     => "Exit",
                'command'   => Proc.new {exit},
                'underline' => 1)

$edit_menu = TkMenu.new($tk_root)
$edit_menu.add( 'command',
                'label'     => "Pass",
                'underline' => 0,
                'command'   => Proc.new { 
                                hide_secret false, true
                                show_word
                                $tk_show.place 'height' => $tk_show_height, 'width' => $tk_show_width, 'x' => $tk_show_x, 'y' => $tk_show_y
                                $tk_yes.unplace
                                $tk_no.unplace
                              })
$edit_menu.add( 'separator' )
$edit_menu.add( 'command',
                'label'     => "Add",
                'command'   => Proc.new { make_win_add },
                'underline' => 0)
$edit_menu.add( 'command',
                'label'     => "Delete",
                'command'   => $menu_click,
                'underline' => 0)
$edit_menu.add( 'command',
                'label'     => "Edit",
                'command'   => $menu_click,
                'underline' => 0)
$edit_menu.add( 'separator' )
$edit_menu.add( 'command',
                'label'     => "Setting",
                'command'   => Proc.new { edit_setting },
                'underline' => 0)

$view_menu = TkMenu.new($tk_root)
$view_menu.add( 'command',
                'label'     => "Wordbook",
                'command'   => $make_wb_win,
                'underline' => 0)

$help_menu = TkMenu.new($tk_root)
$help_menu.add( 'command',
                'label'     => "Roll",
                'underline' => 0,
                'command'   => Proc.new { Tk.messageBox('title' => "Roll",'message' => "Roll: #{rand(100)}") })
$help_menu.add( 'separator' )
$help_menu.add( 'command',
                'label'     => "Usage",
                'underline' => 0,
                'command'   => Proc.new { url = "http://imlane.farbox.com/post/mmrzbang-zhu"; COMM::PLATFORM_WINDOWS ? WIN32OLE.new('Shell.Application').ShellExecute(url) : `open #{url}` })
$help_menu.add( 'command',
                'label'     => "GitHub",
                'underline' => 0,
                'command'   => Proc.new { url = "http://github.com/zhanglintc/Mmrz"; COMM::PLATFORM_WINDOWS ? WIN32OLE.new('Shell.Application').ShellExecute(url) : `open #{url}` })
$help_menu.add( 'command',
                'label'     => "About",
                'underline' => 0,
                'command'   => Proc.new {
                  Tk.messageBox(
                    'type'    => "ok",  
                    'icon'    => "info",
                    'title'   => "About",
                    'message' => show_about )}
              )

$sync_menu = TkMenu.new($tk_root)
$sync_menu.add( 'command',
                'label'     => "Account",
                'command'   => Proc.new { make_win_account },
                'underline' => 0)
$sync_menu.add( 'command',
                'label'     => "Sign up",
                'command'   => Proc.new { make_win_sign_up },
                'underline' => 0)
$sync_menu.add( 'separator' )
$sync_menu.add( 'command',
                'label'     => "Pull",
                'command'   => Proc.new { make_win_pull_push "pull" },
                'underline' => 0)
$sync_menu.add( 'command',
                'label'     => "Push",
                'command'   => Proc.new { make_win_pull_push "push" },
                'underline' => 0)

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
              'menu'  => $sync_menu,
              'label' => "Sync",
              'underline' => 1)
$menu_bar.add('cascade',
              'menu'  => $help_menu,
              'label' => "Help",
              'underline' => 0)
$tk_root.menu($menu_bar)

"""
Main functions.
"""
def move_cursor need_move
  if $cursor_of_rows == $rows_from_DB.size
    $cursor_of_rows = 0
    return
  end

  if not need_move
    return
  end

  $cursor_of_rows += 1
  $cursor_of_rows = 0 if $cursor_of_rows == $rows_from_DB.size
end

def show_word
  if $rows_from_DB.size == 0
    $tk_root.title "#{TITLE} -- #{COMM::get_shortest_remind}"
    $tk_word.text "本次背诵完毕"
    $tk_exit.place 'height' => $tk_show_height, 'width' => $tk_show_width, 'x' => $tk_show_x, 'y' => $tk_show_y
  else
    $tk_word.text $rows_from_DB[$cursor_of_rows][0]
    $tk_root.title "#{TITLE} -- #{$rows_from_DB.size} words left"
  end
end

def show_secret
  $secret_is_hiding = false
  $tk_pronounce.text $rows_from_DB[$cursor_of_rows][1]
  speak_word if TTSSupport and COMM::AUTO_SPEAK
end

def hide_secret remember, pass
  $secret_is_hiding = true
  if $rows_from_DB.empty?
    Tk.messageBox 'message' => "No word specified"
    return
  end

  if remember or pass
    row = $rows_from_DB[$cursor_of_rows]
    firstTimeFail = row[6]
    row[2] += 1 if not firstTimeFail
    row[2] = COMM::MAX_MEM_TIMES if pass
    row[3] = COMM::cal_remind_time row[2], "int"
    row[4] = COMM::cal_remind_time row[2], "str"

    # use thread to avoid UI refresh lagging
    Thread.start do
      sleep 0.01 # sleep some seconds to avoid updateDB and refresh UI at same time
      dbMgr = MmrzDBManager.new
      dbMgr.updateDB row
      dbMgr.closeDB
      $tk_root.title "#{TITLE} -- #{COMM::get_shortest_remind}" if $rows_from_DB.size == 0
    end

    $rows_from_DB.delete_at $cursor_of_rows
    move_cursor false
  else
    $rows_from_DB[$cursor_of_rows][6] = true # firstTimeFail: false => true
    move_cursor true
  end
  $tk_pronounce.text ""
end

def make_GUI
  $tk_root.title TITLE # would be overridden
  $tk_root.iconbitmap FAVICON
  $tk_root.minsize $tk_root_width, $tk_root_height
  $tk_root.maxsize $tk_root_width, $tk_root_height

  $tk_word.borderwidth 0
  $tk_word.font TkFont.new 'simsun 20 bold'
  $tk_word.foreground "black"
  $tk_word.relief "groove"
  $tk_word.place 'height' => $tk_word_height, 'width' => $tk_word_width, 'x' => $tk_word_x, 'y' => $tk_word_y

  $tk_pronounce.borderwidth 0
  $tk_pronounce.font TkFont.new 'simsun 15'
  $tk_pronounce.foreground "black"
  $tk_pronounce.relief "groove"
  $tk_pronounce.place 'height' => $tk_pronounce_height, 'width' => $tk_pronounce_width, 'x' => $tk_pronounce_x, 'y' => $tk_pronounce_y

  $tk_show.text '查看'
  $tk_show.background "yellow"
  $tk_show.foreground "blue"
  $tk_show.place('height' => $tk_show_height, 'width' => $tk_show_width, 'x' => $tk_show_x, 'y' => $tk_show_y) if $secret_is_hiding
  $tk_show.command do
    show_secret
    $tk_show.unplace
    $tk_yes.place 'height' => $tk_yes_height,'width' => $tk_yes_width,'x' => $tk_yes_x,'y' => $tk_yes_y
    $tk_no.place 'height' => $tk_no_height, 'width' => $tk_no_width, 'x' => $tk_no_x, 'y' => $tk_no_y
  end

  $tk_exit.text '退出'
  $tk_exit.background "yellow"
  $tk_exit.foreground "blue"
  $tk_exit.command do
    exit
  end

  $tk_yes.text '记得住'
  $tk_yes.background "yellow"
  $tk_yes.foreground "blue"
  $tk_yes.place 'height' => $tk_yes_height,'width' => $tk_yes_width,'x' => $tk_yes_x,'y' => $tk_yes_y if not $secret_is_hiding
  $tk_yes.command do
    hide_secret true, false
    show_word
    $tk_show.place 'height' => $tk_show_height, 'width' => $tk_show_width, 'x' => $tk_show_x, 'y' => $tk_show_y
    $tk_yes.unplace
    $tk_no.unplace
  end

  $tk_no.text '记不住'
  $tk_no.background "yellow"
  $tk_no.foreground "blue"
  $tk_no.place 'height' => $tk_no_height, 'width' => $tk_no_width, 'x' => $tk_no_x, 'y' => $tk_no_y if not $secret_is_hiding
  $tk_no.command do
    hide_secret false, false
    show_word
    $tk_show.place 'height' => $tk_show_height, 'width' => $tk_show_width, 'x' => $tk_show_x, 'y' => $tk_show_y
    $tk_yes.unplace
    $tk_no.unplace
  end
end

"""
Entry point
"""
if __FILE__ == $0
  """
  table UNMMRZ:
  [0]word           -- char[255]
  [1]pronounce      -- char[255]
  [2]memTimes       -- int
  [3]remindTime     -- int
  [4]remindTimeStr  -- char[255]
  [5]wordID         -- int
  """

  check_update if COMM::AUTO_CHECK_UPDATE # automatically check for update at startup

  $tts_speaker.speak "", 1 if TTSSupport # speak a null word at beginning

  dbMgr = MmrzDBManager.new
  dbMgr.createDB
  dbMgr.closeDB

  dbMgr = MmrzDBManager.new
  $rows_from_DB = []
  dbMgr.readDB.each do |row|
    if COMM::REVERSE_MODE
      if row[1].gsub(/ /, "") =~ /(.*)--(.*)/
        word = row[0]
        pronounce = $1
        meaning   = $2
        row[0] = meaning
        row[1] = "#{word} -- #{pronounce}"
      else
        row[0], row[1] = row[1], row[0]
      end
    end

    # [0~5]read from DB, [6]new added firstTimeFail
    row[6] = false # initialize firstTimeFail as false

    if COMM::REVERSE_MODE
      $rows_from_DB << row if row[2] == COMM::REVERSE_MODE_TIMES
    else
      $rows_from_DB << row if row[3] < Time.now.to_i
    end
  end
  $cursor_of_rows = 0
  dbMgr.closeDB

  make_size
  make_GUI
  show_word
  Tk.mainloop
end


