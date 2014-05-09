require 'cachinguele'

class Cachinguele::KlassAndMethods 
  attr_reader :klass, :method_name
  def initialize(klass, method_names, expiration_policies)
    @klass                = klass
    @method_names         = method_names
    @expiration_policies  = expiration_policies
  end

  def activate_cache
    redefine_methods(@klass, @method_names) do |klass, original_method, &aliased_method|
      Rails.cache.fetch("#{klass.name.underscore}:#{original_method}") do 
        aliased_method.call
      end
    end
  end

  def activate_expiration_policies
    redefine_methods(@klass, @method_names) do |klass, original_method, &aliased_method|
      Rails.cache.delete("#{klass.name.underscore}:#{original_method}")
      aliased_method.call 
    end
  end

end
