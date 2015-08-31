module Kernel
   def login_scope
      kasdb = PStore.new(KasPay::LOGIN_PATH)
      kasdb.transaction do
         yield(kasdb)
      end
   end
 
   def login_data_exists? login_name
      data = nil
      begin
         login_scope {|login| data = login.roots}
         # PStore.new(KasPay::LOGIN_PATH).tap{|x| x.transaction{ data = x.roots}}
         return (data.any? {|name| name == login_name})
      rescue NameError
         return false
      end
   end

   def clear_login login_name = nil
      login_scope do |login|
         if !login_name.nil?
            login.delete login_name
         elsif login_name.nil?
            login.roots.each do |name|
               login.delete name
            end
         end
      end  
   end

end
