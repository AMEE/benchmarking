require 'rubygems'
require 'net/https'
require 'nokogiri'

module Ihsh

  def self.get(url, options = {})
    request(Net::HTTP::Get, url, options)
  end

  def self.post(url, options = {})
    request(Net::HTTP::Post, url, options)
  end

  def self.request(req_type, url, options = {})
    url = URI.parse(url)
    # Make connection to server
    http = Net::HTTP.new(url.host, url.port)
    if url.port == 443
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    # Create request
    req = req_type.new(url.request_uri)
    req['Accept'] = options.delete(:accept) if options[:accept]
    req['ContentType'] = options.delete(:content_type) if options[:content_type]
    req.body = options.delete(:body) if options[:body]
    if options[:username] && options[:password]
      req.basic_auth options.delete(:username), options.delete(:password)
    end
    response = nil
    http.start do
      response = http.request req
    end
    return response.body
  end

  def self.xpath(data, path)
    doc = Nokogiri.XML(data) { |config| config.strict }
    doc.remove_namespaces!
    nodes = doc.xpath(path)
    return nodes
  end
end