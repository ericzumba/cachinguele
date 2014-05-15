require 'spec_helper'
require 'cachinguele/custom_cache_implementation'

describe Cachinguele::CustomCacheImplementation do

  context 'setup' do
    it 'fake cache implementation works' do
      original_implementation = FakeCacheImplementation.new
      original_implementation.fetch('wow') { 'WOOOW' }
      expect(original_implementation.fetch('wow') {'bummer'}).to eql 'WOOOW'
      original_implementation.delete('wow')
      expect(original_implementation.fetch('wow') { 'YAY' }).to eql 'YAY'
    end
  end

  subject do 
    Cachinguele::CustomCacheImplementation.new(FakeCacheImplementation.new)
  end

  context 'always' do
    it 'translates transparently to underlying implementation' do subject.fetch('Helper:heavy_computation') { 42 }
      expect(subject.fetch('Helper:heavy_computation') { 33 }).to eql 42 
      subject.delete('Helper:heavy_computation')
      expect(subject.fetch('Helper:heavy_computation') { 33 }).to eql 33 
    end
  end

  context 'with scoped keys' do
    it 'retains the scoped keys' do
      subject.fetch('Helper:heavy_computation#diguinho') { 42 }
      expect(subject.fetch('Helper:heavy_computation#diguinho') { 33 }).to eql 42 
      subject.delete('Helper:heavy_computation#diguinho')
      expect(subject.fetch('Helper:heavy_computation#diguinho') { 33 }).to eql 33 
    end

    it 'batch deletes all scoped caches' do
      subject.fetch('Helper:heavy_computation') { 55 }
      subject.fetch('Helper:heavy_computation#diguinho') { 42 }

      subject.delete('Helper:heavy_computation')
      expect(subject.fetch('Helper:heavy_computation') { 11 }).to eql 11 
      expect(subject.fetch('Helper:heavy_computation#diguinho') { 33 }).to eql 33 
    end
  end
  context 'effects on the underlying cache implementation' do
    before :each do
      @underlying_cache = double(:underlying_cache)
      @cache = Cachinguele::CustomCacheImplementation.new(@underlying_cache)
    end

    context "when one of the expiration policies' methods is called" do
      context 'and two cached methods need to be invalidated' do
        it 'orders all caches within scope to be deleted' do

          expect(@underlying_cache).to receive(:read).with('scopes@Helper:heavy_computation').and_return(['diguinho'])
          expect(@underlying_cache).to receive(:delete).with('scopes@Helper:heavy_computation')
          expect(@underlying_cache).to receive(:delete).with('Helper:heavy_computation#diguinho')
          expect(@underlying_cache).to receive(:delete).with('Helper:heavy_computation')

          expect(@underlying_cache).to receive(:read).with('scopes@Helper:some_other_heavy_lifting').and_return(['diguinho'])
          expect(@underlying_cache).to receive(:delete).with('scopes@Helper:some_other_heavy_lifting')
          expect(@underlying_cache).to receive(:delete).with('Helper:some_other_heavy_lifting#diguinho')
          expect(@underlying_cache).to receive(:delete).with('Helper:some_other_heavy_lifting')

          @cache.delete "Helper:heavy_computation"
          @cache.delete "Helper:some_other_heavy_lifting"
        end
      end
    end
  end
end
