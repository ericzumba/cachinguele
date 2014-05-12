require 'cachinguele'

class Cachinguele::ExpirationPolicy

  def initialize(klass_and_methods)
    @klass_and_methods = klass_and_methods
  end

  def activate
    @klass_and_methods.apply_to_each_method do |klass, method_name, key|
      Cachinguele::Redefiner.redefine_method(klass, method_name, lambda do |klass, original_method, original_implementation|
        Cachinguele::Register.implementation.delete(key)
        original_implementation.call 
      end)
    end
  end
end
