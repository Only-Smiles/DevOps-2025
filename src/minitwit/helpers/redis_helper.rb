module RedisHelper
  # Redis connection helper
  def self.redis
    @redis ||= begin
      redis_url = ENV.fetch('REDIS_URL', 'redis://redis:6379/0')
      Redis.new(url: redis_url)
    end
  end

  # Instance method to access the class methods
  def redis
    RedisHelper.redis
  end

  # Cache a value with a TTL
  def cache_set(key, value, ttl = 3600)
    redis.set(key, value.to_json, ex: ttl)
  end

  # Get a cached value
  def cache_get(key)
    data = redis.get(key)
    data ? JSON.parse(data, symbolize_names: true) : nil
  end

  # Delete a cached value
  def cache_delete(key)
    redis.del(key)
  end

  # Close the Redis connection
  def self.close_redis
    redis.quit if @redis
    @redis = nil
  end

  def close_redis
    RedisHelper.close_redis
  end

  at_exit do
    puts 'Closing Redis connections...'
    close_redis
  end
end 