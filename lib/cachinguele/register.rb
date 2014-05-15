require 'cachinguele'
require 'cachinguele/caches'

class Cachinguele::Register
  attr_reader :implementation
  def initialize(cache_implementation)
    @implementation = cache_implementation
  end

  def do_it
    caches = Cachinguele::Caches.new(@implementation)
    yield(caches) 
    caches.each do |cache|
      cache.activate 
    end
  end
end
