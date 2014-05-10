require 'cachinguele'
require 'cachinguele/klass_and_methods'

class Cachinguele::Caches < Array
  def register(klass_and_method_as_hash, expiration_policies)
    klass_and_method_as_hash.each do |klass, method_name|
      self << Cachinguele::KlassAndMethods.new(klass, method_name, expiration_policies)
    end
  end
end
