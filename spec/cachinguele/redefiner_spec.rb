require 'cachinguele/redefiner'

describe Cachinguele::Redefiner do
  before :each do

    # resets Cat class for tests
    if defined? Object::Cat
      Object.send(:remove_const, :Cat)
    end

    class Cat 
      def mew 
        'meow'
      end

      def walk(where_to)
        "walking #{where_to}"
      end

      def barfs(what, where)
       "#{what} #{where}" 
      end

      def complicated_barfs(what, where)
        if block_given?
          barfs("#{yield what}", where)    
        else
          "i think i'm allright"
        end
      end
    end

    expect(Cat.new.mew).to eq 'meow'
    expect(Cat.new.walk 'home').to eq 'walking home'
    expect(Cat.new.barfs 'beer', 'on the floor').to eq 'beer on the floor'
    expect(Cat.new.complicated_barfs('beer', 'on the floor') {|what| "old #{what}"} ).to eq 'old beer on the floor'
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

    it 'does NOT work with a lambda called from within a block' do
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
    context 'with no parameters' do
      it 'calls a given block as follows' do
        l = lambda do |klass, method_name|
          expect(klass).to eq Cat
          expect(method_name).to eq :mew 
        end
        Cachinguele::Redefiner.redefine_method(Cat, :mew, l)
      end

      context 'when wrap around method is empty' do
        it 'it leaves the original implementation untouched' do
          l = lambda { |klass, method_name, original_implementation, scope| original_implementation.call } 
          Cachinguele::Redefiner.redefine_method(Cat, :mew, l)
          expect(Cat.new.mew).to eq 'meow'
        end
      end

      context 'when wrap around method is really wraps around' do
        it 'it leaves the original implementation untouched' do
          l = lambda do |klass, method_name, original_implementation, scope|
            "#{original_implementation.call} very important stuff" 
          end
          Cachinguele::Redefiner.redefine_method(Cat, :mew, l)
          expect(Cat.new.mew).to eq 'meow very important stuff'
        end
      end
    end

    context 'with one parameter' do
      context 'when wrap around method is empty' do
        it 'it leaves the original implementation untouched' do
          l = lambda { |klass, method_name, original_implementation, scope| original_implementation.call } 
          Cachinguele::Redefiner.redefine_method(Cat, :walk, l)
          expect(Cat.new.walk('home')).to eq 'walking home'
        end
      end

      context 'when wrap around method is really wraps around' do
        it 'it leaves the original implementation untouched' do
          l = lambda do |klass, method_name, original_implementation, scope|
            "#{original_implementation.call} right now" 
          end
          Cachinguele::Redefiner.redefine_method(Cat, :walk, l)
          expect(Cat.new.walk('home')).to eq 'walking home right now'
        end
      end
    end

    context 'with n parameters' do
      context 'when wrap around method is empty' do
        it 'it leaves the original implementation untouched' do
          l = lambda { |klass, method_name, original_implementation, scope| original_implementation.call } 
          Cachinguele::Redefiner.redefine_method(Cat, :barfs, l)
          expect(Cat.new.barfs('beer', 'on the floor')).to eq 'beer on the floor'
        end
      end

      context 'when wrap around method is really wraps around' do
        it 'it leaves the original implementation untouched' do
          l = lambda do |klass, method_name, original_implementation, scope|
            "all my #{original_implementation.call}" 
          end
          Cachinguele::Redefiner.redefine_method(Cat, :barfs, l)
          expect(Cat.new.barfs('beer', 'on the floor')).to eq 'all my beer on the floor'
        end
      end


      context 'and a block is expected' do
        context 'and given' do
          context 'when wrap around method is empty' do
            it 'it leaves the original implementation untouched' do
              l = lambda { |klass, method_name, original_implementation, scope| original_implementation.call } 
              Cachinguele::Redefiner.redefine_method(Cat, :complicated_barfs, l)
              expect(Cat.new.complicated_barfs('beer', 'on the floor') {|what| "old #{what}"}).to eq 'old beer on the floor'
            end
          end

          context 'when wrap around method is really wraps around' do
            it 'it leaves the original implementation untouched ' do
              l = lambda do |klass, method_name, original_implementation, scope|
                "all my #{original_implementation.call}" 
              end
              Cachinguele::Redefiner.redefine_method(Cat, :complicated_barfs, l)
              expect(Cat.new.complicated_barfs('beer', 'on the floor') {|what| "old #{what}"}).to eq 'all my old beer on the floor'
            end
          end
        end

        context 'and NOT given' do
          context 'when wrap around method is empty' do
            it 'it leaves the original implementation untouched' do
              l = lambda { |klass, method_name, original_implementation, scope| original_implementation.call } 
              Cachinguele::Redefiner.redefine_method(Cat, :complicated_barfs, l)
              expect(Cat.new.complicated_barfs('beer', 'on the floor')).to eq "i think i'm allright" 
            end
          end

          context 'when wrap around method is really wraps around' do
            it 'it leaves the original implementation untouched ' do
              l = lambda do |klass, method_name, original_implementation, scope|
                "after all #{original_implementation.call}" 
              end
              Cachinguele::Redefiner.redefine_method(Cat, :complicated_barfs, l)
              expect(Cat.new.complicated_barfs('beer', 'on the floor')).to eq "after all i think i'm allright"
            end
          end
        end
      end

    end
  end
end
