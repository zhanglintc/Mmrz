#!/env/bin/ruby
# encoding: utf-8

# user defined constants
MMRZ_BUILD_WINDOWS_EXE = false

# constants
WINDOWS = RbConfig::CONFIG['target_os'] == "mingw32" ? true : false

def find_misaki
  misaki_found = false
  if WINDOWS
    $speaker = WIN32OLE.new('Sapi.SpVoice')
    $speaker.GetVoices().each do |engine|
      if engine.GetDescription().include? "Misaki"
        $speaker.Voice = engine
        $speaker.volume = 100 # range 0(low) - 100(loud)
        $speaker.rate  = -3 # range -10(slow) - 10(fast)
        misaki_found = true
      end
    end
  end
  return misaki_found
end

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

def split_remindTime remindTime
  if remindTime > 0
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
  day, hour, min, sec = split_remindTime remindTime
  min += 1 if sec > 0

  remindTimeStr = format("%sd-%sh-%sm", day, hour, min)
  format("Next after %s", remindTimeStr)
end


