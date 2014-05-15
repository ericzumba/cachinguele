require 'cachinguele'
require 'cachinguele/method'

class Cachinguele::Redefiner
  
  REDEFINER_PREFIX = 'cachinguele_redefined'

  def self.redefine_method(klass, method_name, prefix = REDEFINER_PREFIX, new_implementation)
    klass.class_eval do
      alias_method "#{prefix}_#{method_name}".to_sym, method_name 
      define_method method_name do |*args, &block|
        method = Cachinguele::Method.new

        method.klass = klass
        method.name = method_name
        method.retrieve_self = lambda do
          self 
        end

        method.original_implementation = lambda do
          send("#{prefix}_#{method_name}".to_sym, *args, &block)
        end

        new_implementation.call(method)
      end
    end
  end
end
