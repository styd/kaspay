module MetaStuff
   def before(names)
      names.each do |name|
         m = instance_method(name)
         n = instance_method(yield)
         define_method(name) do |*args, &block|
            n.bind(self)
            m.bind(self).(*args, &block)
         end
      end
      private yield
   end
end
