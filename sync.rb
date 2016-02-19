#!/env/bin/ruby
# encoding: utf-8

require File.dirname(__FILE__) + '/comm.rb'

require 'net/http'

class MmrzSync
  def urlencode params
    URI.escape(params.collect{|k, v| "#{k}=#{v}"}.join('&'))
  end

  def version_to_int ver
    ver.gsub(/[^\d]/, "").to_i
  end

  def get_remote_version
    begin
      uri = URI "#{COMM::SERVERADDR}/?" + urlencode('req_thing' => 'version_info')
      rec = JSON.parse Net::HTTP.get(uri)
      return rec['version_info']['GUI']
    rescue
      return nil
    end
  end

  def get_word_book username, password
    params = {
      'username' => username,
      'password' => password,
    }

    uri = URI("#{COMM::SERVERADDR}/download_wordbook/?" + urlencode(params))
    received = JSON.parse Net::HTTP.get(uri)

    verified = received['verified']
    if not verified
      return false
    end
    
    rows = received['wordbook']

    dbMgr = MmrzDBManager.new
    dbMgr.pruneDB
    rows.each do |row|
      dbMgr.insertDB row
    end
    dbMgr.closeDB

    return true
  end
end

