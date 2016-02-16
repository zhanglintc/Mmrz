#!/env/bin/ruby
# encoding: utf-8

require 'json'
require 'nkf'

class ConfigManager
  @@Default_file_path = File.dirname(__FILE__) + "/conf/preferences-default.json"
  @@User_file_path    = File.dirname(__FILE__) + "/preferences-user.json"

  def user_conf_exist?
    begin
      f = open @@User_file_path
      f.close
    rescue
      return false
    end

    return true
  end

  def make_user_conf
    fr = open @@Default_file_path, "rb"
    default_setting = fr.read
    fr.close

    fw = open @@User_file_path, "wb"
    fw.write default_setting
    fw.close
  end

  def format_user_conf
    fr = open @@User_file_path, "rb"
    user_setting = fr.read
    fr.close

    # remove BOM & add CR
    # refer to: http://blog.sina.com.cn/s/blog_63eb3eec01015yk1.html
    user_setting = NKF.nkf("-w -c", user_setting)

    fw = open @@User_file_path, "wb"
    fw.write user_setting
    fw.close
  end

  def get_default_json
    fr = open @@Default_file_path, "rb"
    setting = JSON.parse fr.read
    fr.close

    return setting
  end

  def get_user_json
    fr = open @@User_file_path, "rb"
    setting = JSON.parse fr.read
    fr.close

    return setting
  end

  def get_settings item
    default_setting = get_default_json
    user_setting = get_user_json

    return user_setting[item] != nil ? user_setting[item] : default_setting[item]
  end

  def refresh
    load File.dirname(__FILE__) + '/comm.rb'
    $tk_root.minsize $tk_root_width, $tk_root_height
    $tk_root.maxsize $tk_root_width, $tk_root_height
    $tk_root.update
  end
end
