module MetaStuff
  def method_missing(m, *args, &block)  
    raise NoMethodError, "undefined method `#{m}' for #{self}:#{self.class}"
  end  

  def before(names, &block)
    names.each do |name|
      m = instance_method(name)
      n = instance_method(yield)
      define_method(name) do
        n.bind(self).call 
        m.bind(self).call
      end
    end
    private yield
  end
end
