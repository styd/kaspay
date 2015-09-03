class KasPay
   # inner class Money
   class Money
      attr_accessor :value
      
      fixnum_methods_to_discard = %w(inspect -@ abs magnitude to_s dclone ~ & | ^ [] << >> size bit_length to_f).map(&:to_sym)
      new_methods = Fixnum.instance_methods(false) \
         .delete_if{|m| fixnum_methods_to_discard.include? m}
      
      # Inheriting some methods from Fixnum
      new_methods.each do |m|
         define_method(m) do |arg, &block|
            arg = arg.to_i # to convert string or Money object to Integer 
            self.value = value.send(m, arg)
            return self
         end
      end
      
      def initialize value = 0
         @value = Integer(value)
      end
      
      def to_f
         value * 1.0
      end
      
      def to_s
         "Rp " + value.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse + ".00"
      end

      def inspect
         "#<#{self.class}:0x#{(object_id << 1).to_s(16)} value=#{value}>"
      end
               
      alias_method :to_i, :value
   end
end
