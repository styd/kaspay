#!/usr/bin/env ruby
# @author Adrian Setyadi
# Copyright 2015
# 
require 'pstore'
require 'watir'
require 'headless'
require_relative 'meta_stuff'
require_relative 'kaspay/money'

class KasPay
   # Assigns methods from MetaStuff module as KasPay class methods
   extend MetaStuff

   # A bunch of KasPay constants.
   BASE_URL = "https://www.kaspay.com"
   LOGIN_URL = BASE_URL + "/login" 
   DATA_DIR = ENV['HOME'] + "/.kaspay"
   LOGIN_PATH = DATA_DIR + "/login.dat"
   COOKIE_PATH = DATA_DIR + "/cookie.dat"

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
   
      def all_get_methods
        instance_methods.grep(/^get_/)
      end
      
      def things_to_get
         all_get_methods.map{|m| m.id2name.sub("get_","")}
      end
   
      def data_scope path, &block
         kasdb = PStore.new(path)
         kasdb.transaction do
            yield(kasdb)
         end
      end

      def login_scope(&block)
         data_scope(LOGIN_PATH, &block)
      end
    
      def login_data_exists? login_name
         data = nil
         begin
            login_scope {|login| data = login.roots}
            return data.include? login_name
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

      def load_login login_name
         raise LoadLoginError, "login data \"#{login_name}\" cannot be found" unless login_data_exists? login_name
         email, password = nil
         login_scope do |login|
            email = login[login_name][:email]
            password = login[login_name][:password]
         end
         login email: email, password: password
      end
   
      def cookies_scope(&block)
         data_scope(COOKIE_PATH, &block)
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
   private :browser
   private :browser=
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
   # provided. This is different from the class method
   # `login` that only creates KasPay object and compounding the
   # data for login. 
   def login 
      headless = Headless.new
      headless.start
      
      @browser = Watir::Browser.start LOGIN_URL

      # Delete all expired cookies
      delete_cookies_if_expire
      # Use unexpired cookies that match the given email and password
      the_cookies = use_cookies

      # Fresh login
      if the_cookies.nil?
         browser.text_field(id: 'username').set email
         browser.text_field(id: 'password').set password
         browser.button(name: 'button').click
         save_cookies
      # Cookies still exist
      else
         browser.cookies.clear
         the_cookies.each do |cookie|
            browser.cookies.add(cookie[:name], cookie[:value])
         end
         browser.goto BASE_URL 
      end
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
      return nil
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
   
   def get_transaction
      date, trxID, remarks, debit, credit = Array.new(5){[]}

      %w(date trxID remarks).each do |column|
         browser.tds(class: column).each do |td|
            column << td.text
         end
      end

      browser.tds(class: "amount").each_slice(2) do |tda, tdb|
         debit << tda.text   
         credit << tdb.text
      end

      t = {date: date,
           trxID: trxID,
           remarks: remarks,
           debit: debit,
           credit: credit}
   end

   def home
      goto "/"
   end

   def logout!
      calling_method = caller[0][/(?<=`).*(?=')/]
      logout_link.click
      delete_cookies unless calling_method == "delete_cookies"
   end
  
   # Silently logs out 
   def logout
      logout! if logged_in?
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
      return nil
   end
   
   def check_login
      raise LoginError, "you are not logged in" unless logged_in?
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
   
   before( all_get_methods + [:logout!] ){ :check_login }
   alias_method :url, :current_url
 
private
   
   def get_cookies
      browser.cookies.to_a
   end
 
   def current_cookies_scope
      KasPay.cookies_scope do |cookies|
         cookies.roots.reverse.each do |cookies_name|
            if cookies[cookies_name][:email] == email \
                  && cookies[cookies_name][:password] == password
               yield(cookies, cookies_name)
            end
         end
      end
   end
   
   def delete_cookies_if_expire 
      current_cookies_scope do |cookies, cookies_name|
         cookies[cookies_name][:cookies].each do |el|
            if el[:name] == "kaspay_csrf_cookie" \
                  && DateTime.parse(el[:expires].to_s) < DateTime.now
               cookies.delete(cookies_name)
            end
         end
      end
   end

   def delete_cookies 
      current_cookies_scope do |cookies, cookies_name|
         cookies.delete(cookies_name)
      end
      logout! if logged_in?
      return nil
   end
    
   def save_cookies
      time = Time.now
      cookies_name = time.strftime("%y%m%d%H%M%S").to_i.to_s(36)
      Dir.mkdir(DATA_DIR) unless Dir.exists?(DATA_DIR)
      KasPay.cookies_scope do |cookie|
         cookie[cookies_name] = {email: email, password: password, cookies: get_cookies}
      end
   end

   def use_cookies
      the_cookie = nil
      current_cookies_scope do |cookies, cookies_name|
         the_cookie = cookies[cookies_name][:cookies]
      end
      return the_cookie
   end

   def logout_link
      logout_link = browser.a(href: "https://www.kaspay.com/account/logout")
   end
end

# Aliases for 'KasPay' class
Kaspay = KasPay
KASPAY = KasPay

class LoginError < StandardError
end

class LoadLoginError < StandardError
end
