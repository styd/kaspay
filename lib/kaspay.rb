#!/usr/bin/env ruby
# @author Adrian Setyadi
# Copyright 2015
# 
require 'pstore'
require 'watir'
require 'headless'
require_relative 'meta_stuff'

class KasPay
   # Assigns methods from MetaStuff module as KasPay class methods
   extend MetaStuff

   # A bunch of KasPay constants.
   BASE_URL = "https://www.kaspay.com"
   LOGIN_URL = BASE_URL + "/login" 
   DATA_DIR = ENV['HOME'] + "/.kaspay"
   LOGIN_PATH = DATA_DIR + "/login.dat"

   # Opening KasPay class singleton scope
   class << self
      
      # A list of kaspay.com static pages to open for the sake of  
      # the information.
      static_pages = %w(about term) # more will come
     
      # Iterates through static pages list to make methods named the
      # the same as the member of the list. These methods will be
      # the class methods of KasPay.
      # Example usage:
      #     `about_page = KasPay.about`
      static_pages.each do |page|
         define_method(page) do
            # Watir::Browser object is created when it's not exist.
            browse BASE_URL if (defined?(@@browser)).nil?
            @@browser.goto "#{BASE_URL}/#{page}"
            @@browser.div(id: "body").text
         end
      end

      # Creates Watir::Browser object for navigating web pages.
      def browse url
         @@headless = Headless.new
         @@headless.start
         @@browser = Watir::Browser.start url
      end 

      # Creates an alias for `KasPay.term` method, which is 
      # `KasPay.terms`
      alias_method :terms, :term

      # Changes class method `new` to `login` (the more natural
      # name) to make an instance of KasPay.
      alias_method :login, :new
      # Hidden to force the use of `login` as the class method
      # for instantiation.

      def load_login login_name
         raise LoadLoginError, "login data \"#{login_name}\" cannot be found" unless login_data_exists? login_name
         email, password = nil
         login_scope do |login|
            email = login[login_name][:email]
            password = login[login_name][:password]
         end
         login email: email, password: password
      end
 
      def login_data_exists? login_name
         data = nil
         begin
            PStore.new(LOGIN_PATH).tap{|x| x.transaction{ data = x.roots}}
            return (data.any? {|name| name == login_name})
         rescue NameError
            return false
         end
      end
  
      def clear_login login_name = nil
         login_scope do |login|
            if login_name.any?
               login.delete login_name
            elsif login_name.nil?
               login.roots.each do |name|
                  login.delete name
               end
            end
         end  
      end
   
      def login_scope
         kasdb = PStore.new(LOGIN_PATH)
         kasdb.transaction do
            yield(kasdb)
         end
      end
 
      private :new
   end
   
   # Creates browser and headless methods for browsing without
   # a visible browser or 'head', and email and password methods
   # for reading @email and @password instance variables.
   attr_accessor :browser
   attr_accessor :headless
   attr_reader :email
   attr_reader :password
  
   # Some methods need to be inaccessible
   private :headless
   private :headless=
   private :password

   # Accept a hash argument from class methods `login`
   def initialize user = { email: nil, password: nil }
      unless user[:email] == nil || user[:password] == nil
         @email = user[:email]
         @password = user[:password]
         login 
      end
   end
   
   # Actually starts the login process after email and password
   # provided. This is actualy different from the class method
   # `login` that only creates KasPay object and compounding the
   # data for login. 
   def login 
      headless = Headless.new
      headless.start
      
      @browser = Watir::Browser.start LOGIN_URL

      browser.text_field(id: 'username').set email
      browser.text_field(id: 'password').set password
      browser.button(name: 'button').click
   end

   # Sets email input
   def email= mail
      @email = mail
      login if user_data_complete?
   end

   # Sets password input
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
   
   def self.all_get_methods
     instance_methods.grep(/^get_/)
   end
   
   def self.things_to_get
      all_get_methods.map{|m| m.id2name.sub("get_","")}
   end
   
   def home
      goto "/"
   end

   def logout
      logout_link.click
   end
   
   def logout!
      logout if logged_in?
   end
   
   def logged_in?
      return logout_link.exists? unless browser.nil?
      return false
   end

   def logged_out?
      return !logged_in?
   end

   def user_data_complete?
      !email.nil? && !password.nil? 
   end

   def save_login login_name
      Dir.mkdir(DATA_DIR) unless Dir.exists?(DATA_DIR)
      KasPay.login_scope do |login|
         login[login_name] = {email: email, password: password}
      end
   end

   def inspect
      "#<#{self.class}:0x#{(object_id << 1).to_s(16)} logged_in=#{logged_in?}>"
   end

   def method_missing(m, *args, &block)  
      if KasPay.things_to_get.include? m.id2name
         send("get_#{m}")
      else
         super
      end 
   end 
   
   def check_login
      raise LoginError, "you are not logged in" unless logged_in?
   end
   
   before( all_get_methods + [:logout] ){ :check_login }
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

class LoginError < StandardError
end

class LoadLoginError < StandardError
end
