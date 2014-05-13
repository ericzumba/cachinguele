require 'cachinguele'

class Cachinguele::Redefiner
  
  REDEFINER_PREFIX = 'cachinguele_redefined'

  def self.redefine_method(klass, method_name, prefix = REDEFINER_PREFIX, wrap_around)
    arity = klass.instance_method(method_name).arity
    klass.class_eval do
    alias_method "#{prefix}_#{method_name}".to_sym, method_name 
      define_method method_name do |*args, &block|

        original_implementation = lambda do
          send("#{prefix}_#{method_name}".to_sym, *args, &block)
        end

        scope = lambda do
          self 
        end

        wrap_around.call(klass, method_name, original_implementation, scope)
      end
    end
  end
end
