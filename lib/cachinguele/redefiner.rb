require 'cachinguele'

class Cachinguele::Redefiner
  
  REDEFINER_PREFIX = 'cachinguele_redefined'

  def self.redefine_method(klass, method_name, wrap_around)
    arity = klass.instance_method(method_name).arity
    klass.class_eval do
      alias_method "#{REDEFINER_PREFIX}_#{method_name}".to_sym, method_name 
      if arity == 0
        define_method method_name do
          wrap_around.call(klass, method_name, lambda do
            send("#{REDEFINER_PREFIX}_#{method_name}".to_sym)
          end)
        end
      else
        define_method method_name do |*args|
          wrap_around.call(klass, method_name, lambda do
            send("#{REDEFINER_PREFIX}_#{method_name}".to_sym, *args)
          end)
        end
      end
    end
  end
end
