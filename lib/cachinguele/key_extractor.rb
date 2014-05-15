require 'cachinguele'

class Cachinguele::KeyExtractor
  def namespace_and_scope(key)
    key.split("#")
  end
end
