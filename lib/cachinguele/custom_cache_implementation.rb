require 'cachinguele'
require 'cachinguele/key_extractor'

# original implementation as established on
# http://api.rubyonrails.org/classes/ActiveSupport/Cache/Store.html

class Cachinguele::CustomCacheImplementation
  
  MEMORY_PREFIX = 'scopes@'

  def initialize(original)
    @original = original
    @extractor = Cachinguele::KeyExtractor.new
  end

  def fetch(*args, &block)
    namespace, scope = @extractor.namespace_and_scope(args.first) 
    save_to_scopes_related_to_this_namespace(namespace, scope)
    @original.fetch(*args, &block)
  end

  def delete(*args)
    whole_key = args.first
    namespace, scope = @extractor.namespace_and_scope(whole_key) 
    unless scope
      delete_all_scopes_related_to_this_namespace(namespace)
    end
    @original.delete(*args)
  end

  private 

  def save_to_scopes_related_to_this_namespace(namespace, scope) 
    memory = @original.fetch(memory_key_for(namespace)) do
      []
    end
    memory << scope
    @original.write(memory_key_for(namespace), memory)
  end

  def delete_all_scopes_related_to_this_namespace(namespace)
    memory = @original.read(memory_key_for(namespace))
    if(memory)
      memory.each do |scope|
        @original.delete("#{namespace}##{scope}")
      end
    end
    @original.delete(memory_key_for(namespace))
  end

  def memory_key_for(namespace)
    "#{MEMORY_PREFIX}#{namespace}"
  end
end
