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

    # resets Dog class for tests
    if defined? Object::Dog
      Object.send(:remove_const, :Dog)
    end

    class Dog 
      attr_accessor :bark, :howl
      def initialize(how_to_bark = 'woof', how_to_howl = 'aaw aaaaaw')
        @bark, @howl = how_to_bark, how_to_howl
      end
    end

    if defined? Object::DogsFriend
      Object.send(:remove_const, :DogsFriend)
    end
    
    class DogsFriend
      def tells_her_differently
      end

      def criticizes_it
      end 
    end

    expect(Dog.new('woof').bark).to eq 'woof'
    Cachinguele::Register.implementation = FakeCacheImplementation.new {}
  end

  it 'fake cache implementation works' do
    Cachinguele::Register.implementation.fetch('wow') { 'WOOOW' }
    expect(Cachinguele::Register.implementation.fetch('wow') {'bummer'}).to eql 'WOOOW'
    Cachinguele::Register.implementation.delete('wow')
    expect(Cachinguele::Register.implementation.fetch('wow') { 'YAY' }).to eql 'YAY'
  end

  context 'when applied to a single object instance' do
    it 'overrides a method behaviour with its latest cache' do 
      subject.do_it do |cache|
        cache.register({ Dog => [:bark] }, { DogsFriend =>  [:tells_her_differently] })
      end
      bonita = Dog.new('woof')
      expect(bonita.bark).to eq 'woof' 
      bonita.bark = 'arf arf'
      expect(bonita.bark).to eq 'woof'
    end

    it 'overrides all method behaviours with their latest caches' do 
      subject.do_it do |cache|
        cache.register({ Dog => [:bark, :howl] }, { DogsFriend =>  [:tells_her_differently] })
      end
      bonita = Dog.new('woof')
      expect(bonita.bark).to eq 'woof' 
      bonita.bark = 'arf arf'
      expect(bonita.bark).to eq 'woof'
      bonita.howl = 'aaw aaaaaw'
      expect(bonita.howl).to eq 'aaw aaaaaw'
      bonita.howl = 'eew eeeeew'
      expect(bonita.howl).to eq 'aaw aaaaaw'
    end

    context "one of the expiration policy's methods is called" do 
      it 'restores a cached method behaviour' do 
        subject.do_it do |cache|
          cache.register({ Dog => [:bark, :howl] }, { DogsFriend =>  [:tells_her_differently] })
        end
        bonita = Dog.new('woof', 'aaw aaaaaw')
        expect(bonita.bark).to eq 'woof' 
        expect(bonita.howl).to eq 'aaw aaaaaw' 
        bonita.bark = 'arf arf'
        expect(bonita.bark).to eq 'woof'
        bonita.howl = 'eew eeeeew'
        expect(bonita.howl).to eq 'aaw aaaaaw' 

        DogsFriend.new.tells_her_differently
        expect(bonita.bark).to eq 'arf arf'
        expect(bonita.howl).to eq 'eew eeeeew' 
      end

      it 'restores a cached method behaviour' do 
        subject.do_it do |cache|
          cache.register({ Dog => [:bark, :howl] }, { DogsFriend =>  [:tells_her_differently, :criticizes_it] })
        end
        bonita = Dog.new('woof', 'aaw aaaaaw')
        expect(bonita.bark).to eq 'woof' 
        expect(bonita.howl).to eq 'aaw aaaaaw' 
        bonita.bark = 'arf arf'
        expect(bonita.bark).to eq 'woof'
        bonita.howl = 'eew eeeeew'
        expect(bonita.howl).to eq 'aaw aaaaaw' 

        DogsFriend.new.criticizes_it
        expect(bonita.bark).to eq 'arf arf'
        expect(bonita.howl).to eq 'eew eeeeew' 
      end

    end
  end

  context 'when applied to a another object instance of the same class' do
    it 'overrides a method behaviour with its latest cache' do 
      subject.do_it do |cache|
        cache.register({ Dog => [:bark] }, { DogsFriend =>  [:tells_her_differently] })
      end

      expect(Dog.new('woof').bark).to eq 'woof' 
      expect(Dog.new('arf arf').bark).to eq 'woof' 
    end
   
    context "one of the expiration policy's methods is called" do 
      it 'restores a cached method behaviour' do 
        subject.do_it do |cache|
          cache.register({ Dog => [:bark, :howl] }, { DogsFriend =>  [:tells_her_differently] })
        end

        expect(Dog.new('woof').bark).to eq 'woof' 
        expect(Dog.new('arf arf').bark).to eq 'woof'
        expect(Dog.new('woof', 'aw aaw').howl).to eq 'aw aaw' 
        expect(Dog.new('woof', 'ew eew').howl).to eq 'aw aaw'
        DogsFriend.new.tells_her_differently
        expect(Dog.new('arf arf').bark).to eq 'arf arf'
        expect(Dog.new('arf arf', 'ew eew').howl).to eq 'ew eew'
      end

      it 'restores a cached method behaviour' do 
        subject.do_it do |cache|
          cache.register({ Dog => [:bark, :howl] }, { DogsFriend =>  [:tells_her_differently, :criticizes_it] })
        end

        expect(Dog.new('woof').bark).to eq 'woof' 
        expect(Dog.new('arf arf').bark).to eq 'woof'
        expect(Dog.new('woof', 'aw aaw').howl).to eq 'aw aaw' 
        expect(Dog.new('woof', 'ew eew').howl).to eq 'aw aaw'
        DogsFriend.new.criticizes_it
        expect(Dog.new('arf arf').bark).to eq 'arf arf'
        expect(Dog.new('arf arf', 'ew eew').howl).to eq 'ew eew'
      end
    end
  end

end

