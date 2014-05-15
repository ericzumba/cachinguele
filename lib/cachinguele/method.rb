require 'cachinguele'

class Cachinguele::Method
  attr_accessor :klass, :name, :retrieve_self, :original_implementation

  def key
    "#{klass}:#{name}"
  end
end
