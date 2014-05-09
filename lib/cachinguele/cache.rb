require 'cachinguele'

class Cachinguele::Cache

  class Caches < Array
    def register(klass_and_method_as_hash, expiration_policies)
      klass_and_method_as_hash.each do |klass, method_name|
        self << KlassAndMethods.new(klass, method_name, expiration_policies)
      end
    end
  end

  class KlassAndMethods 
    attr_reader :klass, :method_name
    def initialize(klass, method_names, expiration_policies)
      @klass                = klass
      @method_names         = method_names
      @expiration_policies  = expiration_policies
    end

    def activate_cache
      redefine_methods(@klass, @method_names, "uncached") do |klass, original_method, &aliased_method|
        Rails.cache.fetch("#{klass.name.underscore}:#{original_method}") do 
          aliased_method.call
        end
      end
    end

    def activate_expiration_policies
      redefine_methods(@klass, @method_names, "original") do |klass, original_method, &aliased_method|
        Rails.cache.delete("#{klass.name.underscore}:#{original_method}")
        aliased_method.call 
      end
    end

    def redefine_methods(klass, method_names, prefix)
      klass.class_eval do
        method_names.each do |method_name|
          original = klass.instance_method(method_name)
          define_method method_name do
            yield klass, method, lambda { original.call }
          end

          # aliased_method = "#{prefix}_#{original_method}".to_sym
          # alias_method aliased_method, original_method
          # define_method original_method do # descobrir a arity do original method
          #   yield klass, original_method, aliased_method
          # end
        end
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
