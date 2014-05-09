require 'cachinguele/redefiner'

class Cat 
  def mew 
    'meow'
  end

end


describe Cachinguele::Redefiner do

  it 'works' do 
    wrap_around = lambda do |klass, method_name, original_method_as_lambda|
      klass.should eql Cat
      method_name.should eql method_name
      original_method_as_lambda.call.should eql 'meow'
    end
    Cachinguele::Redefiner.redefine_methods(Cat, [:mew], wrap_around)
  end

end
