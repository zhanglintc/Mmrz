#!/env/bin/ruby
# encoding: utf-8

require File.dirname(__FILE__) + '/config.rb'

class MacSpeaker
  # text is word to be said
  # paraX is useless, only to make speaker() can accept two parameters
  def speak text, paraX
    Thread.start do
      `say #{text} -v kyoko`
    end
  end
end

module COMM
  configMgr = ConfigManager.new
  if not configMgr.user_conf_exist?
    configMgr.make_user_conf
  end
  configMgr.format_user_conf

  default_setting = configMgr.get_default_json
  user_setting = configMgr.get_user_json

  ## User defined constants
  MAX_MEM_TIMES = 8
  MAIN_WIN_WIDTH = configMgr.get_settings "MAIN_WIN_WIDTH"
  MAIN_WIN_HEIGHT = configMgr.get_settings "MAIN_WIN_HEIGHT"
  WB_WIN_WIDTH = configMgr.get_settings "WB_WIN_WIDTH"
  WB_WIN_HEIGHT = configMgr.get_settings "WB_WIN_HEIGHT"
  AUTO_CHECK_UPDATE = configMgr.get_settings "AUTO_CHECK_UPDATE"
  DEBUG_MODE = configMgr.get_settings "DEBUG_MODE"
  MMRZ_BUILD_WINDOWS_EXE = configMgr.get_settings "MMRZ_BUILD_WINDOWS_EXE"
  USE_TTS_ENGINE = configMgr.get_settings "USE_TTS_ENGINE"
  AUTO_SPEAK = configMgr.get_settings "AUTO_SPEAK"
  REVERSE_MODE = configMgr.get_settings "REVERSE_MODE"
  REVERSE_MODE_TIMES = configMgr.get_settings "REVERSE_MODE_TIMES"

  ## Constants
  PLATFORM_WINDOWS = RbConfig::CONFIG['target_os'] == "mingw32"
  PLATFORM_MAC = RUBY_PLATFORM.include? "darwin"
  PLATFORM_LINUX = RUBY_PLATFORM.include? "linux"
  SERVERADDR = true ? "http://115.29.192.240:2603" : "http://127.0.0.1:2603"

  module_function # public functions begin
  def cal_remind_time memTimes, type
    curTime = Time.now

    case memTimes
    when 0
      remindTime = curTime + (60 * 5) # 5 minutes
      remindTime = curTime if COMM::DEBUG_MODE # 0 minutes, debug mode
    when 1
      remindTime = curTime + (60 * 30) # 30 minutes
    when 2
      remindTime = curTime + (60 * 60 * 12) # 12 hours
    when 3
      remindTime = curTime + (60 * 60 * 24) # 1 day
    when 4
      remindTime = curTime + (60 * 60 * 24 * 2) # 2 days
    when 5
      remindTime = curTime + (60 * 60 * 24 * 4) # 4 days
    when 6
      remindTime = curTime + (60 * 60 * 24 * 7) # 7 days
    when 7
      remindTime = curTime + (60 * 60 * 24 * 15) # 15 days
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

  def split_remindTime remindTime, adjust = false
    if remindTime > 0
      remindTime += 59 if adjust
      day  = remindTime / (60 * 60 * 24)
      hour = remindTime % (60 * 60 * 24) / (60 * 60)
      min  = remindTime % (60 * 60 * 24) % (60 * 60) / 60
      sec  = remindTime % (60 * 60 * 24) % (60 * 60) % 60
    else
      day = hour = min = sec = 0
    end

    return day, hour, min, sec
  end

  def get_shortest_remind
    dbMgr = MmrzDBManager.new
    rows = dbMgr.readDB
    dbMgr.closeDB
    return "No words in schedule" if rows == []

    rows.sort! { |r1, r2| r1[3] <=> r2[3] } # remindTime from short to long
    word          = rows[0][0]
    pronounce     = rows[0][1]
    memTimes      = rows[0][2]
    remindTime    = rows[0][3]
    remindTimeStr = rows[0][4]
    wordID        = rows[0][5]

    remindTime -= Time.now.to_i
    day, hour, min, sec = split_remindTime remindTime, true

    remindTimeStr = format("%sd-%sh-%sm", day, hour, min)
    format("Next after %s", remindTimeStr)
  end

  def get_OS
    if RUBY_PLATFORM.include? "darwin"
      return "mac"
    elsif RUBY_PLATFORM.include? "linux"
      return "linux"
    else
      return "win"
    end
  end

  def find_misaki?
    if COMM::PLATFORM_WINDOWS
      speaker = WIN32OLE.new('Sapi.SpVoice')
      speaker.GetVoices().each do |engine|
        if engine.GetDescription().include? "Misaki"
          begin
            speaker.speak "", 1
            return true
          rescue
            p "audio device not available"
          end
        end
      end
    end
    return false
  end

  def make_speaker
    if COMM::PLATFORM_WINDOWS
      speaker = WIN32OLE.new('Sapi.SpVoice')
      speaker.GetVoices().each do |engine|
        if engine.GetDescription().include? "Misaki"
          speaker.Voice = engine
          speaker.volume = 100 # range 0(low) - 100(loud)
          speaker.rate  = -3 # range -10(slow) - 10(fast)
          return speaker
        end
      end
    end

    if COMM::PLATFORM_MAC
      speaker = MacSpeaker.new
      return speaker
    end
  end

end # end of module COMM

