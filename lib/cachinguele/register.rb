require 'cachinguele'
require 'cachinguele/caches'

class Cachinguele::Register

  def self.implementation=(i)
    @implementation = i
  end

  def self.implementation
    @implementation
  end

  def do_it
    caches = Cachinguele::Caches.new
    yield(caches) # register cache for all methods
    caches.each do |cache|
      cache.activate 
    end
  end
end
