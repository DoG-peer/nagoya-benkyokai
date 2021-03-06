# encoding: utf-8
require 'net/http'
require 'uri'
require 'open-uri'
require 'json'

class Http
  def self.get_document(url)
    charset = nil
    html = open(url) do |f|
      charset = f.charset
      f.read
    end
    Nokogiri::HTML.parse(html, charset)
  end

  def self.get_json(url)
    url_escape = URI.escape(url)
    self.get_json_core(url_escape)
  end

  def self.get_json_core(url, limit = 10)
    raise ArgumentError, 'too many HTTP redirects' if limit == 0
    uri = URI.parse(url)
    begin
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.open_timeout = 5
        http.read_timeout = 10
        http.get(uri.request_uri)
      end
      case response
      when Net::HTTPSuccess
        json = response.body
        JSON.parse(json, {:symbolize_names => true})
      when Net::HTTPRedirection
        location = response['location']
        warn "redirected to #{location}"
        get_json_core(location, limit - 1)
      else
        puts [uri.to_s, response.value].join(" : ")
        # handle error
      end
    rescue => e
      puts [uri.to_s, e.class, e].join(" : ")
      # handle error
    end
  end
end
