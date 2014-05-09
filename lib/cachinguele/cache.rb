require 'cachinguele'

class Cachinguele::Cache

  class Caches < Array
    def register(klass_and_method_as_hash, expiration_policies)
      klass_and_method_as_hash.each do |klass, method_name|
        self << KlassAndMethods.new(klass, method_name, expiration_policies)
      end
    end
  end


  def self.global
    caches = Caches.new
    yield(caches) # register all cache for all methods
    caches.each do |cache|
      cache.activate_cache 
      cache.activate_expiration_policies
    end
  end

end
