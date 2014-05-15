require 'cachinguele/scope'
require 'ostruct'

describe Cachinguele::Scope do
  before :all do
    if defined? Object::Cavaco
      Object.send(:remove_const, :Cavaco)
    end

    class Cavaco
      def chora
        OpenStruct.new(:agora => 'blim blim') 
      end
    end
  end

  context 'when used' do
    it 'works' do
      expect(Cachinguele::Scope.new('chora.agora').evaluate_within(Cavaco.new)).to eq 'blim blim'
    end
  end
end
