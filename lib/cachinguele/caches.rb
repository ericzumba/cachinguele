require 'cachinguele'
require 'cachinguele/cache'
require 'cachinguele/expiration_policy'
require 'cachinguele/klass_and_methods'

class Cachinguele::Caches < Array

  def initialize(cache_implementation)
    @cache_implementation = cache_implementation
  end

  def register(caches, expiration_policies)
    caches.each do |klass, methods_and_scope|
      self << Cachinguele::Cache.new(Cachinguele::KlassAndMethods.new(klass, methods_and_scope), expiration_policies, @cache_implementation)
    end
  end
end
