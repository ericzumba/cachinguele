require 'cachinguele'

class Cachinguele::Scope
  def initialize(what_to_eval)
    @what_to_eval = what_to_eval
  end
  
  def evaluate_within(context)
    if @what_to_eval 
      context.instance_eval(@what_to_eval) 
    else
      nil
    end
  end
end
