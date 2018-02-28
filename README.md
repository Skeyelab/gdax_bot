Prerequisites for OSX
---------------------

-   RVM  
    `gpg --keyserver hkp://keys.gnupg.net --recv-keys
    409B6B1796C275462A1703113804BB82D39DC0E3
    7D2BAF1CF37B13E2069D6956105BD0E739499BDB`  
      
    `\curl -sSL https://get.rvm.io | bash -s stable`  
    

-   Homebrew  
    `/usr/bin/ruby -e "$(curl -fsSL
    https://raw.githubusercontent.com/Homebrew/install/master/install)"`  
    

-   Redis  
    `brew install redis`  
    

Installation
------------

`git clone https://github.com/Skeyelab/gdax_bot.git`

`cd gdax_bot`

`gem install bundler`

`bundle update`

`cp .env.example .env`

`open .env `(This should open .env in TextEdit)

Add your GDAX API info, and if you use Pushover, your User Key, and save the
file.

 

Usage
-----

`ruby gdax.rb`

 

1.  Trailing Stop

     
