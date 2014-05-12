require 'cachinguele/register'

describe Cachinguele::Register do
  before :all do
    class FakeCacheImplementation
      def initialize(cache = {})
        @cache = cache 
      end

      def fetch(key)
        if @cache[key] then
          @cache[key]
        else
          @cache[key] = yield
        end
      end

      def delete(key)
        @cache.delete(key) 
      end
    end

  end

  before :each do
    class Dog 
      attr_writer :how_to_bark
      def initialize(how_to_bark)
        @how_to_bark = how_to_bark
      end

      def bark 
        @how_to_bark
      end
    end
    
    class DogsFriend
      def tells_her_differently

      end
    end

    expect(Dog.new('woof').bark).to eq 'woof'
    Cachinguele::Register.implementation = FakeCacheImplementation.new {}
  end

  it 'fake cache implementation works' do
    Cachinguele::Register.implementation.fetch('wow') { 'WOOOW' }
    expect(Cachinguele::Register.implementation.fetch('wow') {'bummer'}).to eql 'WOOOW'
    Cachinguele::Register.implementation.delete('wow')
    expect(Cachinguele::Register.implementation.fetch('wow') {'YAY'}).to eql 'YAY'
  end

  context 'when applied to a single object instance' do
    it 'overrides a method behaviour with its latest cache' do 
      subject.do_it do |cache|
        cache.register({ Dog => [:bark] }, { DogsFriend =>  [:tells_her_differently] })
      end
      bonita = Dog.new('woof')
      expect(bonita.bark).to eq 'woof' 
      bonita.how_to_bark = 'arf arf'
      expect(bonita.bark).to eq 'woof'

      expect(Dog.new('arf arf').bark).to eq 'woof' 
    end
  end

  context 'when applied to a another object instance of the same class' do
    it 'overrides a method behaviour with its latest cache' do 
      subject.do_it do |cache|
        cache.register({ Dog => [:bark] }, { DogsFriend =>  [:tells_her_differently] })
      end
      bonita = Dog.new('woof')
      expect(bonita.bark).to eq 'woof' 
      bonito = Dog.new('arf arf')
      expect(bonito.bark).to eq 'woof' 
    end
  end

end

