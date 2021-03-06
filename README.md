# KasPay
## Description  
A ruby library to access [KasPay](https://www.kaspay.com) with your account.  

## Installation  
Install the X virtual framebuffer that we will use to run the Watir::Browser  

    sudo apt-get install xvfb     

and then:  

    gem install kaspay    
    
## Usage  
Put this code wherever you're going to use it:  

    require 'kaspay'  

In `Gemfile`:  

    gem 'kaspay'

## Examples
### Code
```ruby
require 'kaspay'

kaspay = KasPay.login email: "email@example.com", password: "yOurp@sSw0rD"
# Alternative:
# kaspay = KasPay.login
# kaspay.email = "email@example.com"
# kaspay.password = "yOurp@sSw0rD"
puts "#{kaspay.get_name}'s savings with account number #{kaspay.get_acc_num}:"
# `<method>` is an alias for `get_<method>`. So, you can use `kaspay.name` or `kaspay.acc_num` instead.
puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
puts " Bank A balance".ljust(15) + ": " + "Rp 500,000.00".rjust(20)
puts " Bank B balance".ljust(15) + ": " + "Rp 600,000.00".rjust(20)
puts " KasPay balance".ljust(15) + ": " + kaspay.get_balance.to_s.rjust(20)
puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
puts " Total balance".ljust(15) + ": " + (kaspay.balance + 500000 + KasPay::Money.new(600000)).to_s.rjust(20)
puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
kaspay.logout!
```
### Output  
```ruby
#=> John Doe's savings with account number 12345678:
#=> ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#=>  Bank A balance:        Rp 500,000.00
#=>  Bank B balance:        Rp 600,000.00
#=>  KasPay balance:        Rp 915,826.00
#=> ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#=>  Total balance :      Rp 2,015,826.00
#=> ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```
