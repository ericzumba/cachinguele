require 'cachinguele'
require 'cachinguele/cache'
require 'cachinguele/klass_and_methods'

class Cachinguele::Caches < Array
  def register(cached_methods_as_hash, expiration_policies)
    cached_methods_as_hash.each do |klass, method_name|
      self << Cachinguele::Cache.new(Cachinguele::KlassAndMethods.new(klass, method_name))
    end
  end
end
