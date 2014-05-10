require 'cachinguele/cache'

describe Cachinguele::Cache do
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
    Cachinguele::Cache.implementation = FakeCacheImplementation.new {}
  end

  it 'FakeCacheImplementation works' do
    Cachinguele::Cache.implementation.fetch('wow') { 'WOOOW' }
    expect(Cachinguele::Cache.implementation.fetch('wow') {'bummer'}).to eql 'WOOOW'
    Cachinguele::Cache.implementation.delete('wow')
    expect(Cachinguele::Cache.implementation.fetch('wow') {'YAY'}).to eql 'YAY'
  end

  it 'works' do 
    subject.do_it do |cache|
      cache.register({ Dog => [:bark] }, { DogsFriend =>  [:tells_her_differently] })
    end
    expect(Dog.new('woof').bark).to eq 'woof' 
  end

end

