require 'cachinguele'

class Cachinguele::KlassAndMethods 
  attr_reader :klass, :method_names
  def initialize(klass, method_names)
    @klass                = klass
    @method_names         = method_names
  end

  def apply_to_each_method
    @method_names.each do |method_name| 
      yield klass, method_name, build_key(method_name)
    end
  end
 
  private

  def build_key(method_name)
    "#{klass.name}:#{method_name}"
  end

end
