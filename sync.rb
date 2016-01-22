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
      uri = URI 'http://zhanglin.work:2603/?' + urlencode('req_thing' => 'version_info')
      rec = JSON.parse Net::HTTP.get(uri)
      return rec['version_info']['GUI']
    rescue
      return nil
    end
  end
end

