#!/usr/bin/env ruby

require 'watir'
require 'headless'
require_relative 'meta_stuff'
require_relative 'kernel_patch'

class KasPay
   extend MetaStuff

   class << self
      static_pages = %w(about term)
      static_pages.each do |page|
         define_method(page) do
            browse BASE_URL if (defined?(@@browser)).nil?
            @@browser.goto "#{BASE_URL}/#{page}"
            @@browser.div(id: "body").text
         end
      end

      def browse url
         @@headless = Headless.new
         @@headless.start
         @@browser = Watir::Browser.start url
      end 

      alias_method :terms, :term
      alias_method :login, :new
      private :new
   end

   BASE_URL = "https://www.kaspay.com"
   LOGIN_URL = BASE_URL + "/login" 
   THINGS_TO_GET = %w(name balance acc_num).map(&:to_sym)
   THE_GET_METHODS = add__get__to(THINGS_TO_GET)
   
   attr_accessor :browser
   attr_accessor :headless
   attr_reader :email
   attr_reader :password
   private :headless
   private :headless=

   def initialize user = { email: "", password: "" }
      headless = Headless.new
      headless.start
      
      @browser = Watir::Browser.start LOGIN_URL

      unless user[:email] == "" || user[:password] == ""
         email = user[:email]
         password = user[:password]
         login 
      end
   end
   
   def login 
      browser.text_field(id: 'username').set email
      browser.text_field(id: 'password').set password
      browser.button(name: 'button').click
   end

   def email= mail
      @email = mail
      login if user_data_complete?
   end

   def password= pass 
      @password = pass
      login if user_data_complete?
   end

   def current_url
      browser.url
   end

   def goto path
      url = (path[0] == "/" ? (BASE_URL + path) : path)
      browser.goto url
   end
   
   def get_name
      browser.span(class: "user-name").text
   end
   
   def get_balance
      Money.new browser.div(class: "kaspay-balance") \
         .span.text.sub("Rp ","").sub(".","").to_i
   end
   
   def get_acc_num 
      browser.span(class: "kaspay-id").text.sub("KasPay Account: ", "").to_i
   end
   
   def home
      goto "/"
   end
   
   def logout!
      logout_link.click
   end
   
   def logged_in?
      return logout_link.exists? unless browser.nil?
      return false
   end

   def logged_out?
      return !logged_in?
   end

   def user_data_complete?
      email != "" && password != "" 
   end

   def inspect
      "#<#{self.class}:0x#{(object_id << 1).to_s(16)}>"
   end
   
   def method_missing(m, *args, &block)  
      if THINGS_TO_GET.include? m
         send("get_#{m}")
      else
         raise NoMethodError, "undefined method `#{m}' for #{self}"
      end 
   end 
   
   def check_login
      raise LoginError, "you are not logged in" unless logged_in?
   end
   
   before( THE_GET_METHODS + [:logout!] ){ :check_login }
   
   alias_method :logout, :logout!
   alias_method :url, :current_url
   
private

   def logout_link
      logout_link = browser.a(href: "https://www.kaspay.com/account/logout")
   end

   # inner class Money
   class Money
      attr_accessor :value
      
      fixnum_methods_to_discard = %w(inspect -@ abs magnitude to_s dclone ~ & | ^ [] << >> size bit_length to_f).map(&:to_sym)
      new_methods = Fixnum.instance_methods(false) \
         .delete_if{|m| fixnum_methods_to_discard.include? m}
      
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
      
      alias_method :to_i, :value
   end
end

class LoginError < StandardError
end

class UserDataError < StandardError
end
