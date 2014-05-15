require 'cachinguele'

class Cachinguele::KlassAndMethods 
  attr_reader :klass, :method_names, :scope
  def initialize(klass, methods)
    @klass                = klass
    @method_names         = methods[:methods]
    @scope                = Cachinguele::Scope.new(methods[:scope])
  end

  def apply_to_each_method
    @method_names.each do |method_name| 
      yield klass, method_name, scope
    end
  end
end
