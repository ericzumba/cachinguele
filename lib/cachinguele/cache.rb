require 'cachinguele'

class Cachinguele::Cache

  def initialize(klass_and_methods, expiration_policies_as_hash)
    @klass_and_methods = klass_and_methods
    @expiration_policies = []
    expiration_policies_as_hash.each do |expiration_klass, expiration_methods|
      @expiration_policies << Cachinguele::ExpirationPolicy.new(Cachinguele::KlassAndMethods.new(expiration_klass, expiration_methods))
    end
  end

  def activate
    @expiration_policies.each do |expiration_policy|
      expiration_policy.activate_for(self)
    end

    @klass_and_methods.apply_to_each_method do |klass, method_name, key|
      Cachinguele::Redefiner.redefine_method(klass, method_name, 'cachinguele_cached', lambda do |klass, original_method, original_implementation, scope|
        Cachinguele::Register.implementation.fetch(key) do 
          original_implementation.call
        end
      end)
    end
  end

  def expire_all_methods
    @klass_and_methods.apply_to_each_method do |klass, method_name, key|
      Cachinguele::Register.implementation.delete(key)
    end
  end
end
