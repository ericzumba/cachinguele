require 'cachinguele'
require 'cachinguele/scope'

class Cachinguele::Cache
  def initialize(klass_and_methods, expiration_policies, cache_implementation)
    @klass_and_methods = klass_and_methods
    @expiration_policies = []
    expiration_policies.each do |expiration_klass, expiration_methods_and_scope|
      @expiration_policies << Cachinguele::ExpirationPolicy.new(Cachinguele::KlassAndMethods.new(expiration_klass, expiration_methods_and_scope))
    end
    @cache_implementation = cache_implementation
  end

  def activate
    @expiration_policies.each do |expiration_policy|
      expiration_policy.activate_for(self)
    end

    @klass_and_methods.apply_to_each_method do |klass, method_name, scope|
      Cachinguele::Redefiner.redefine_method(klass, method_name, 'cachinguele_cached', lambda do |method|
        scope_for_key = scope.evaluate_within(method.retrieve_self.call)
        @cache_implementation.fetch(build_key(klass, method_name, scope_for_key)) do 
          method.original_implementation.call
        end
      end)
    end
  end

  def expire_all_methods(expiration_scope)
    @klass_and_methods.apply_to_each_method do |klass, method_name, scope|
      @cache_implementation.delete(build_key(klass, method_name, expiration_scope))
    end
  end

  def scope
    @klass_and_methods.scope
  end

  private

  def build_key(klass, method_name, scope)
    if scope
      "#{klass}:#{method_name}##{scope}"
    else
      "#{klass}:#{method_name}"
    end
  end
end
