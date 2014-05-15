require 'spec_helper'

require 'cachinguele/custom_cache_implementation'
require 'cachinguele/register'
require 'ostruct'

describe Cachinguele::Register do

  subject do 
    Cachinguele::Register.new(Cachinguele::CustomCacheImplementation.new(FakeCacheImplementation.new {}))
  end

  before :each do

    if defined? Object::Helper
      Object.send(:remove_const, :Helper)
    end

    class Helper 
      attr_accessor :heavy_computation, :some_other_heavy_lifting, :user_login
      def initialize(heavy_computation = 42, some_other_heavy_lifting = 'A', user_login = 'diguinho')
        @heavy_computation, @some_other_heavy_lifting, @user_login = heavy_computation, some_other_heavy_lifting, user_login
      end

      def current_user
        OpenStruct.new(:login => @user_login)
      end
    end

    if defined? Object::Controller
      Object.send(:remove_const, :Controller)
    end
    
    class Controller
      attr_accessor :user_login
      def initialize(user_login = 'diguinho')
        @user_login = user_login  
      end

      def create
      end

      def update
      end 

      def current_user
        OpenStruct.new(:login => @user_login)
      end
    end
  end

  context 'setup' do
    it 'fake cache implementation works' do
      subject.implementation.fetch('Helper:heavy_computation') { 42 }
      expect(subject.implementation.fetch('Helper:heavy_computation') { 55 }).to eql 42 
      subject.implementation.delete('Helper:heavy_computation')
      expect(subject.implementation.fetch('Helper:heavy_computation') { 55 }).to eql 55 
    end
  end

  context 'effects on underlying cache implementation' do
    before :each do 
      @cache_implementation = Cachinguele::CustomCacheImplementation.new(FakeCacheImplementation.new {})
    end
    
    subject do 
      Cachinguele::Register.new(@cache_implementation)
    end

    context "with generic caches and generic invalidation policies" do
      before :each do
        subject.do_it do |cache|
          cache.register( { Helper =>     { :methods => [:heavy_computation, :some_other_heavy_lifting] }}, 
                          { Controller => { :methods => [:create, :update],                             }})
        end
      end

      it 'fetches a from cache' do
        expect(@cache_implementation).to receive(:fetch).with('Helper:heavy_computation')
        expect(@cache_implementation).to receive(:fetch).with('Helper:some_other_heavy_lifting')
        Helper.new.heavy_computation
        Helper.new.some_other_heavy_lifting
      end

      it 'orders all caches to be deleted' do
        expect(@cache_implementation).to receive(:delete).with('Helper:heavy_computation')
        expect(@cache_implementation).to receive(:delete).with('Helper:some_other_heavy_lifting')
        Controller.new.create
      end
    end

    context 'with scoped cache and scoped invalidation policies' do
      before :each do
        subject.do_it do |cache|
          cache.register( { Helper =>     { :methods => [:heavy_computation, :some_other_heavy_lifting],  :scope => 'current_user.login' }}, 
                          { Controller => { :methods => [:create, :update],                               :scope => 'current_user.login' }})
        end
      end

      it 'fetches a cache within scope' do
        expect(@cache_implementation).to receive(:fetch).with('Helper:heavy_computation#diguinho')
        expect(@cache_implementation).to receive(:fetch).with('Helper:some_other_heavy_lifting#diguinho')
        Helper.new.heavy_computation
        Helper.new.some_other_heavy_lifting
      end

      it 'orders all caches within scope to be deleted' do
        expect(@cache_implementation).to receive(:delete).with('Helper:heavy_computation#diguinho')
        expect(@cache_implementation).to receive(:delete).with('Helper:some_other_heavy_lifting#diguinho')
        Controller.new.create
      end
    end

    context "with scoped cache and generic invalidation policy" do
      before :each do
        subject.do_it do |cache|
          cache.register( { Helper =>     { :methods => [:heavy_computation, :some_other_heavy_lifting],  :scope => 'current_user.login' }}, 
                          { Controller => { :methods => [:create, :update] }})
        end
      end

      it 'fetches a cache within scope' do
        expect(@cache_implementation).to receive(:fetch).with('Helper:heavy_computation#diguinho')
        expect(@cache_implementation).to receive(:fetch).with('Helper:some_other_heavy_lifting#diguinho')
        Helper.new.heavy_computation
        Helper.new.some_other_heavy_lifting
      end

      it 'orders all caches within scope to be deleted' do
        expect(@cache_implementation).to receive(:delete).with('Helper:heavy_computation')
        expect(@cache_implementation).to receive(:delete).with('Helper:some_other_heavy_lifting')
        Controller.new.update
      end
    end
  end

  context 'with scope for cache and and generic expiration policies' do
    context 'caching multiple methods' do 
      context 'with multiple methods as expiration policies' do
        before :each do
          subject.do_it do |cache|
            cache.register( { Helper =>     { :methods => [:heavy_computation, :some_other_heavy_lifting],  :scope => 'current_user.login' }}, 
                            { Controller => { :methods => [:create, :update] }})
          end
        end

        context 'for all instances of a cached class' do
          context "when the expiration policy method is called" do
            it 'overrides a method behaviour with its latest cache' do 
              expect(Helper.new(42, 'A').some_other_heavy_lifting).to eq 'A' 
              expect(Helper.new(42, 'E').some_other_heavy_lifting).to eq 'A' 
            end
            it 'restores a cached method behaviour' do 
              expect(Helper.new(42, 'A', 'diguinho').some_other_heavy_lifting).to eq 'A' 
              expect(Helper.new(42, 'X', 'diguinho').some_other_heavy_lifting).to eq 'A' 

              expect(Helper.new(42, 'E', 'udi').some_other_heavy_lifting).to eq 'E' 
              expect(Helper.new(42, 'X', 'udi').some_other_heavy_lifting).to eq 'E' 
              Controller.new.update
              expect(Helper.new(42, 'X', 'diguinho').some_other_heavy_lifting).to eq 'X' 
              expect(Helper.new(42, 'X', 'udi').some_other_heavy_lifting).to eq 'X' 
            end
            context 'when scope changes' do
              it "it bypasses cache and calls the method's original behaviour" do 
                expect(Helper.new(42, 'A').some_other_heavy_lifting).to eq 'A' 
                expect(Helper.new(42, 'E').some_other_heavy_lifting).to eq 'A' 
                expect(Helper.new(42, 'E', 'udi').some_other_heavy_lifting).to eq 'E' 
              end
            end
          end
        end

        context 'for one instance' do
          context "when the expiration policy method is called" do
            it 'overrides a method behaviour with its latest cache' do 
              helper = Helper.new(42, 'A')
              expect(helper.some_other_heavy_lifting).to eq 'A' 
              helper.some_other_heavy_lifting = 'E' 
              expect(helper.some_other_heavy_lifting).to eq 'A' 
            end
            it 'restores a cached method behaviour for all scoped caches' do 
              helper = Helper.new(42, 'A', 'diguinho')
              expect(helper.some_other_heavy_lifting).to eq 'A'
              helper.some_other_heavy_lifting = 'E'
              expect(helper.some_other_heavy_lifting).to eq 'A'

              helper.user_login = 'udi'
              expect(helper.some_other_heavy_lifting).to eq 'E'
              helper.some_other_heavy_lifting = 'X'
              expect(helper.some_other_heavy_lifting).to eq 'E'

              Controller.new.update
              helper.user_login = 'diguinho'
              expect(helper.some_other_heavy_lifting).to eq 'X' 
              helper.user_login = 'udi'
              expect(helper.some_other_heavy_lifting).to eq 'X' 
            end

            context 'when scope changes' do
              it "it bypasses cache and calls the method's original behaviour" do 
                helper = Helper.new(42, 'A')
                expect(helper.some_other_heavy_lifting).to eq 'A' 
                helper.some_other_heavy_lifting = 'E' 
                helper.user_login = 'udi'
                expect(helper.some_other_heavy_lifting).to eq 'E' 
              end
            end
          end
        end
      end
    end
  end

  context 'with scope both for cache and expiration' do
    context 'caching multiple methods' do 
      context 'with multiple methods as expiration policies' do
        before :each do
          subject.do_it do |cache|
            cache.register( { Helper =>     { :methods => [:heavy_computation, :some_other_heavy_lifting],  :scope => 'current_user.login' }}, 
                            { Controller => { :methods => [:create, :update],                               :scope => 'current_user.login' }})
          end
        end

        context 'for all instances of a cached class' do
          context "when the expiration policy method is called" do
            it 'overrides a method behaviour with its latest cache' do 
              expect(Helper.new(42, 'A').some_other_heavy_lifting).to eq 'A' 
              expect(Helper.new(42, 'E').some_other_heavy_lifting).to eq 'A' 
            end
            it 'restores a cached method behaviour' do 
              expect(Helper.new(42, 'A').some_other_heavy_lifting).to eq 'A' 
              Controller.new.update
              expect(Helper.new(42, 'E').some_other_heavy_lifting).to eq 'E' 
            end
            context 'when scope changes' do
              it "it bypasses cache and calls the method's original behaviour" do 
                expect(Helper.new(42, 'A').some_other_heavy_lifting).to eq 'A' 
                expect(Helper.new(42, 'E').some_other_heavy_lifting).to eq 'A' 
                expect(Helper.new(42, 'E', 'udi').some_other_heavy_lifting).to eq 'E' 
              end
            end
          end
        end

        context 'for one instance' do
          context "when the expiration policy method is called" do
            it 'overrides a method behaviour with its latest cache' do 
              helper = Helper.new(42, 'A')
              expect(helper.some_other_heavy_lifting).to eq 'A' 
              helper.some_other_heavy_lifting = 'E' 
              expect(helper.some_other_heavy_lifting).to eq 'A' 
            end
            it 'restores a cached method behaviour' do 
              helper = Helper.new(42, 'A')
              helper.some_other_heavy_lifting = 'E'
              Controller.new.update
              expect(helper.some_other_heavy_lifting).to eq 'E' 
            end
            context 'when scope changes' do
              it "it bypasses cache and calls the method's original behaviour" do 
                helper = Helper.new(42, 'A')
                expect(helper.some_other_heavy_lifting).to eq 'A' 
                helper.some_other_heavy_lifting = 'E' 
                helper.user_login = 'udi'
                expect(helper.some_other_heavy_lifting).to eq 'E' 
              end
            end
          end
        end
      end
    end
  end

  context 'caching one method' do
    context 'with one method as expiration policy' do
      before :each do
        subject.do_it do |cache|
          cache.register( { Helper =>     { :methods => [:heavy_computation]}}, 
                          { Controller => { :methods => [:create],          }})
        end
      end

      context 'for all instances of a cached class' do
        it 'overrides a method behaviour with its latest cache' do 
          expect(Helper.new(42).heavy_computation).to eq 42 
          expect(Helper.new(33).heavy_computation).to eq 42 
        end
      end
    end
  end

  context 'caching multiple methods' do
    context 'with one method as expiration policy' do
      before :each do
        subject.do_it do |cache|
          cache.register( { Helper =>     { :methods => [:heavy_computation, :some_other_heavy_lifting] }}, 
                          { Controller => { :methods => [:create],                                      }})
        end
      end

      context 'for one instance' do
        it 'overrides all methods behaviours with their latest caches' do 
          helper = Helper.new(42, 'A')
          expect(helper.heavy_computation).to eq 42 
          helper.heavy_computation = 33
          expect(helper.heavy_computation).to eq 42
          
          expect(helper.some_other_heavy_lifting).to eq 'A'
          helper.some_other_heavy_lifting = 'E'
          expect(helper.some_other_heavy_lifting).to eq 'A'
        end

        context "when the expiration policy's method is called" do
          it 'restores a cached method behaviour' do 
            helper = Helper.new(42, 'A')
            helper.heavy_computation = 33
            helper.some_other_heavy_lifting = 'E'

            Controller.new.create
            expect(helper.heavy_computation).to eq 33
            expect(helper.some_other_heavy_lifting).to eq 'E' 
          end
        end
      end

      context 'for all instances of a cached class' do
        it 'overrides a method behaviour with its latest cache' do 
          expect(Helper.new(42, 'A').some_other_heavy_lifting).to eq 'A' 
          expect(Helper.new(33, 'E').some_other_heavy_lifting).to eq 'A' 
        end

        context "when the expiration policy's method is called" do
          it 'restores a cached method behaviour' do 
            expect(Helper.new(42, 'A').some_other_heavy_lifting).to eq 'A' 
            Controller.new.create
            expect(Helper.new(33, 'E').some_other_heavy_lifting).to eq 'E' 
          end
        end
      end
    end
    
    context 'with multiple methods as expiration policies' do
      before :each do
        subject.do_it do |cache|
          cache.register( { Helper =>     { :methods => [:heavy_computation, :some_other_heavy_lifting] }}, 
                          { Controller => { :methods => [:create, :update],                             }})
        end
      end

      context 'for one instance' do
        it 'overrides all methods behaviours with their latest caches' do 
          helper = Helper.new(42, 'A')
          expect(helper.heavy_computation).to eq 42 
          helper.heavy_computation = 33
          expect(helper.heavy_computation).to eq 42
          
          expect(helper.some_other_heavy_lifting).to eq 'A'
          helper.some_other_heavy_lifting = 'E'
          expect(helper.some_other_heavy_lifting).to eq 'A'
        end

        context "one of the expiration policies' methods is called" do 
          it 'restores a cached method behaviour' do 
            helper = Helper.new(42, 'A')
            helper.heavy_computation = 33
            helper.some_other_heavy_lifting = 'E'

            Controller.new.update
            expect(helper.heavy_computation).to eq 33
            expect(helper.some_other_heavy_lifting).to eq 'E' 
          end
        end
      end

      context 'for all instances of a cached class' do
        it 'overrides a method behaviour with its latest cache' do 
          expect(Helper.new(42, 'A').some_other_heavy_lifting).to eq 'A' 
          expect(Helper.new(33, 'E').some_other_heavy_lifting).to eq 'A' 
        end

        context "when the one of the expiration policies' methods is called" do
          it 'restores a cached method behaviour' do 
            expect(Helper.new(42, 'A').some_other_heavy_lifting).to eq 'A' 
            Controller.new.update
            expect(Helper.new(33, 'E').some_other_heavy_lifting).to eq 'E' 
          end
        end
      end
    end
  end
end

