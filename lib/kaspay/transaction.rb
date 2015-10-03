class KasPay
   # Inner class Transaction
   class Transaction
      def initialize trx_id, browser
         browser.goto(KasPay::TRANSACTION_URL + trx_id)
         data = []
         browser.tds.each_slice(3){|a, b, c| data << c.text}
         @date = DateTime.parse(data[0] + "T" \
                                   + data[1] + "+07:00")
         @trx_id = data[2]
         @trx_type = data[3]
         @remark = data[4]
         @status = data[5]
         m1_in_sym = []
         instance_variables.each do |v|
            m1_in_sym << v.to_s.sub(/@/, '').to_sym
         end
         m1_in_sym.each do |m|
            self.class.class_eval do
               define_method m do
                  eval "@#{m.to_s}"
               end
            end
         end

         non_payment_type = ["Transaction correction", "Topup"]
         unless non_payment_type.include? @trx_type
            @seller = data[6]
            @merchant_trx_id = data[7]
            @product_id = data[8]
            @product_name = data[9]
            @quantity = data[10].gsub(/[^0-9]/, '').to_i
            @description = data[11]
            m2_in_sym = []
            instance_variables.each do |v|
               m2_in_sym << v.to_s.sub(/@/, '').to_sym
            end
            m2_in_sym = m2_in_sym - m1_in_sym
            m2_in_sym.each do |m|
               singleton_class.class_eval do
                  define_method m do
                     eval "@#{m.to_s}"
                  end
               end
            end
            @amount = Money.new data[12]
         else
            @amount = Money.new data[6]
         end
         self.class.class_eval do
            define_method :amount do
               @amount
            end
         end
      end

      def to_h
         h = {}
         instance_variables.each do |v|
            m_in_sym = v.to_s.sub(/@/, '').to_sym
            h[m_in_sym] = send m_in_sym
         end
         return h
      end

      alias_method :to_s, :to_h
 
      def inspect
         "#<#{self.class}:0x#{(object_id << 1).to_s(16)} id=#{@trx_id}>"
      end

   end
end
