require 'cachinguele'

class Cachinguele::Redefiner
  
  REDEFINER_PREFIX = 'cachinguele_redefined'

  def self.redefine_method(klass, method_name, wrap_around)
    klass.class_eval do
      alias_method "#{REDEFINER_PREFIX}_#{method_name}".to_sym, method_name 
      define_method method_name do
        wrap_around.call(klass, method_name)
        send("#{REDEFINER_PREFIX}_#{method_name}".to_sym)
      end
    end
  end
end
