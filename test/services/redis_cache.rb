require 'test_helper'

class RedisCacheTest < ActiveSupport::TestCase
  test "connects to redis" do
    assert_not RedisCache.redis, nil
  end
end
