class RedisCache
  def self.redis
    if defined? @redis
      return @redis
    end

    @redis = new_connection
  end

  # Heroku Key-Value Store uses rediss:// URLs with self-signed certificates,
  # so we can't verify the peer.
  def self.new_connection
    Redis.new(url: ENV["REDIS_URL"], ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE })
  end
end
