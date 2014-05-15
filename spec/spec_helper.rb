class FakeCacheImplementation
  def initialize(cache = {})
    @cache = cache 
  end

  def write(key, value)
    @cache[key] = value
  end

  def fetch(key)
    value = read(key)
    if value then
      value 
    else
      write(key, yield)
    end
  end

  def read(key)
    @cache[key]
  end

  def delete(key)
    @cache.delete(key) 
  end
end
