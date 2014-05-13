require 'cachinguele'
require 'cachinguele/redefiner'

class Cachinguele::ExpirationPolicy

  def initialize(klass_and_methods)
    @klass_and_methods = klass_and_methods
  end

  def activate_for(cache)
    @klass_and_methods.apply_to_each_method do |klass, method_name, key|
      Cachinguele::Redefiner.redefine_method(klass, method_name, 'cachinguele_expiration_trigger', lambda do |method|
        cache.expire_all_methods
        method.original_implementation.call 
      end)
    end
  end
end
