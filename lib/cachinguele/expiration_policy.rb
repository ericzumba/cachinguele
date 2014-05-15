require 'cachinguele'
require 'cachinguele/redefiner'

class Cachinguele::ExpirationPolicy

  def initialize(klass_and_methods)
    @klass_and_methods = klass_and_methods
  end

  def activate_for(cache)
    @klass_and_methods.apply_to_each_method do |klass, method_name, scope|
      Cachinguele::Redefiner.redefine_method(klass, method_name, 'cachinguele_expiration_trigger', lambda do |method|
        scope_for_key = scope.evaluate_within(method.retrieve_self.call)  
        cache.expire_all_methods(scope_for_key)
        method.original_implementation.call 
      end)
    end
  end

  def scope
    @klass_and_methods.scope
  end
end
