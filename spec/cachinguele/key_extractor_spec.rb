require 'cachinguele/key_extractor'

describe Cachinguele::KeyExtractor do
  context 'when only namespace is provided' do
    it 'works' do
      expect(subject.namespace_and_scope('Helper:heavy_computation')).to eq ['Helper:heavy_computation']
    end
  end

  context 'when namespace and scope are provided' do
    it 'works' do
      expect(subject.namespace_and_scope('Helper:heavy_computation#diguinho')).to eq ['Helper:heavy_computation', 'diguinho']
    end
  end
end
