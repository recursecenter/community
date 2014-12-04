class RedisCache
  def self.redis
    if defined? @redis
      return @redis
    end

    uri = URI.parse(ENV["REDIS_URL"])
    @redis = Redis.new(host: uri.host, port: uri.port, password: uri.password)
  end
end
