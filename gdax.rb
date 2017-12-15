require 'rubygems'
require 'bundler'
Bundler.require
Dotenv.load

load 'functions.rb'

redis = Redis.new

rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])
#wallet = Coinbase::Wallet::Client.new(ENV['CB_KEY'], ENV['CB_SECRET'])
accounts = update_accounts

rest_api.accounts do |resp|
  resp.each do |account|
    p "#{account.id}: %.2f #{account.currency} available for trading" % account.available
  end
end

orders = update_orders
binding.pry

#watch_order_and_rebuy(orders[0], 9300)
#watch_order_and_sell(orders[0], 10510)
