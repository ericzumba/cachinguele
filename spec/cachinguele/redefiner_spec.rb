require 'cachinguele/redefiner'

describe Cachinguele::Redefiner do
  before :each do
    class Cat 
      def mew 
        'meow'
      end
    end
    expect(Cat.new.mew).to eq 'meow'
  end

  describe 'how lambdas work in Ruby' do
    it 'works with a lambda disguised as a block' do
      l = lambda {send(:redefined_mew)}
      Cat.class_eval do
        alias_method :redefined_mew, :mew
        # evaluates the lambda in the context of the object on which :mew is called
        define_method :mew, &l 
      end
      expect(Cat.new.mew).to eq 'meow'
    end

    it 'does NOT work with a pure lambda ' do
      l = lambda {send(:redefined_mew)}
      Cat.class_eval do
        alias_method :redefined_mew, :mew
        define_method :mew do
          # l retains the flat scope and raises NoMethodError for :cachinguele_redefined_mew
          l.call
        end
      end
      expect { Cat.new.mew }.to raise_error 
    end
  end 

  context '#redefine_method' do
    it 'calls a given block as follows' do
      l = lambda do |klass, method_name|
        expect(klass).to eq Cat
        expect(method_name).to eq :mew 
      end
      Cachinguele::Redefiner.redefine_method(Cat, :mew, l)
    end

    context 'when wrap around method is empty' do
      it 'it leaves the original implementation untouched' do
        l = lambda { |klass, method_name, original_implementation| original_implementation.call } 
        Cachinguele::Redefiner.redefine_method(Cat, :mew, l)
        expect(Cat.new.mew).to eq 'meow'
      end
    end

    context 'when wrap around method is really wraps around' do
      it 'it leaves the original implementation untouched' do
        l = lambda do |klass, method_name, original_implementation|
          "#{original_implementation.call} very important stuff" 
        end
        Cachinguele::Redefiner.redefine_method(Cat, :mew, l)
        expect(Cat.new.mew).to eq 'meow very important stuff'
      end
    end
  end

end
