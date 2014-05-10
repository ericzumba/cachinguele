require 'cachinguele'

class Cachinguele::KlassAndMethods 
  attr_reader :klass, :method_name
  def initialize(klass, method_names, expiration_policies)
    @klass                = klass
    @method_names         = method_names
    @expiration_policies  = expiration_policies
  end

  def activate_cache
    @method_names.each do |method_name|
      Cachinguele::Redefiner.redefine_method(@klass, method_name, lambda do |klass, original_method, original_implementation|
        Cachinguele::Cache.implementation.fetch("#{klass.name}:#{original_method}") do 
          original_implementation.call
        end
      end)
    end
  end

  def activate_expiration_policies
    @method_names.each do |method_name|
      Cachinguele::Redefiner.redefine_method(@klass, method_name, lambda do |klass, original_method, original_implementation|
        Cachinguele::Cache.implementation.delete("#{klass.name}:#{original_method}")
        original_implementation.call 
      end)
    end
  end

end
