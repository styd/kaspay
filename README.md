# KasPay
## Description

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
###Code
```ruby
require 'kaspay'

trial = Thread.new do
    while !kaspay.logged_in?
        kaspay = KasPay.login "email@example.com", "Som3p@sSw0rD"
    end
end

begin
    kaspay = KasPay.login "email@example.com", "Som3p@sSw0rD"
    puts "Halo, #{kaspay.get_name}"
    puts "Saldo KasPaymu sekarang #{kaspay.get_balance}"
rescue LoginError => e
    trial.join
    puts "Kamu tidak login. Mencoba login..."
end
```
