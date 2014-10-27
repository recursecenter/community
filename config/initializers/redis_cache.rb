class RedisCache
  def self.redis
    @redis ||= $redis || Redis.new(uri_components)
  end

private
  def self.uri_components
    uri = URI.parse(ENV["REDIS_URL"])
    {host: uri.host, port: uri.port, password: uri.password}
  end
end
