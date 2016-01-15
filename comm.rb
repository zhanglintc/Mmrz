#!/env/bin/ruby
# encoding: utf-8

# user defined constants
MMRZ_BUILD_WINDOWS_EXE = false

# constants
WINDOWS = RbConfig::CONFIG['target_os'] == "mingw32" ? true : false

def find_misaki
  misaki_found = false
  if WINDOWS
    $announcer = WIN32OLE.new('Sapi.SpVoice')
    $announcer.GetVoices().each do |engine|
      if engine.GetDescription().include? "Misaki"
        $announcer.Voice = engine
        $announcer.volume = 100 # range 0(low) - 100(loud)
        $announcer.rate  = -3 # range -10(slow) - 10(fast)
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