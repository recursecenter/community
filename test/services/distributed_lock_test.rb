require 'test_helper'

class DistributedLockTest < ActiveSupport::TestCase
  test "one thread can hold the lock at once" do
    x = 0

    20.times.map do
      lock = DistributedLock.new(:test_distributed_lock_x)
      Thread.new do
        lock.synchronize do
          y = x
          sleep 0.001
          x = y + 1
        end
      end
    end.each(&:join)

    assert_equal 20, x
  end

  test "cleans up stale values" do
    RedisCache.redis.set(:test_distributed_lock, Time.now.to_i - 1)

    start = Time.now
    DistributedLock.new(:test_distributed_lock).synchronize do
      nil
    end

    assert_operator Time.now.to_i - start.to_i, :<, 1
  end
end
