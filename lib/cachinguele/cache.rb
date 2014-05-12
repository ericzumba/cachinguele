require 'cachinguele'

class Cachinguele::Cache

  def initialize(klass_and_methods)
    @klass_and_methods = klass_and_methods
  end

  def activate
    @klass_and_methods.apply_to_each_method do |klass, method_name, key|
      Cachinguele::Redefiner.redefine_method(klass, method_name, lambda do |klass, original_method, original_implementation|
        Cachinguele::Register.implementation.fetch(key) do 
          original_implementation.call
        end
      end)
    end
  end
end
