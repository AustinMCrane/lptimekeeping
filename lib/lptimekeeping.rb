require "lptimekeeping/version"
require 'net/http'
require "uri"

module Lptimekeeping
  class Terminal
    attr_accessible :username, :password
    def initialize
    end
    def self.credintials
      puts "Login Credentials\nusername:"
      username = gets
      puts "password:"
      password = gets
      uri = URI.parse("https://app.liquidplanner.com/api/account/")
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Get.new(uri.request_uri)
      request.basic_auth(username, password)
      response = http.request(request)
      puts response.to_json
    end
    def self.start
      credintials
    end
  end
end
