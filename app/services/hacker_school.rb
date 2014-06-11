require 'oauth2'

class HackerSchool
  attr_reader :client_id, :client_secret, :site, :secret_token

  def self.client_id
    new.client_id
  end

  def self.client_secret
    new.client_secret
  end

  def self.site
    new.site
  end

  def self.secret_token
    new.secret_token or raise "ENV['HACKER_SCHOOL_API_SECRET_TOKEN'] must be set."
  end

  def initialize
    raise 'ENV["HACKER_SCHOOL_CLIENT_ID"] must be set'     unless ENV.has_key?("HACKER_SCHOOL_CLIENT_ID")
    raise 'ENV["HACKER_SCHOOL_CLIENT_SECRET"] must be set' unless ENV.has_key?("HACKER_SCHOOL_CLIENT_SECRET")

    @client_id = ENV['HACKER_SCHOOL_CLIENT_ID']
    @client_secret = ENV['HACKER_SCHOOL_CLIENT_SECRET']
    @secret_token = ENV['HACKER_SCHOOL_API_SECRET_TOKEN']
    @site = ENV['HACKER_SCHOOL_SITE'] || 'https://www.hackerschool.com'
  end

  def client
    @client ||= OAuth2::Client.new(client_id, client_secret, site: site)
  end
end
