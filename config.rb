#!/env/bin/ruby
# encoding: utf-8

require 'json'

class ConfigManager
  @@Default_file_path = "./conf/preferences-default.json"
  @@User_file_path    = "./preferences-user.json"

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
end
