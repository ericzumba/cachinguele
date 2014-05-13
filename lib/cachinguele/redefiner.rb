require 'cachinguele'

class Cachinguele::Redefiner
  
  REDEFINER_PREFIX = 'cachinguele_redefined'

  def self.redefine_method(klass, method_name, prefix = REDEFINER_PREFIX, wrap_around)
    arity = klass.instance_method(method_name).arity
    klass.class_eval do
    alias_method "#{prefix}_#{method_name}".to_sym, method_name 
      define_method method_name do |*args, &block|
        wrap_around.call(klass, method_name, lambda do
          send("#{prefix}_#{method_name}".to_sym, *args, &block)
        end)
      end
    end
  end
end
