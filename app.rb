#!/usr/bin/env ruby
#
# server_1
require 'rubygems'
require 'bundler'
Bundler.require
Dotenv.load

Dir["./inc/*.rb"].each {|file| require file }

redis = Redis.new
require 'rubygems'
require 'eventmachine'

rest_api = Coinbase::Exchange::AsyncClient.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])


bids = Hash.new
asks = Hash.new

module EchoServer
  def post_init
    puts "-- someone connected to the echo server!"
    send_data(":")
  end

  def receive_data data
    redis = Redis.new
    if data == "spot"
      send_data("$%.2f" % redis.get("spot_BTC_USD"))
      send_data(" | ")
      send_data("$%.2f" % redis.get("spot_ETH_USD"))
      send_data(" | ")
      send_data("$%.2f" % redis.get("spot_LTC_USD"))
      send_data(" | ")
      send_data("Ƀ%.8f" % redis.get("spot_ETH_BTC"))
      send_data(" | ")
      send_data("Ƀ%.8f" % redis.get("spot_LTC_BTC"))
    end
  end
end



#load 'websocket.rb'

websocket = Coinbase::Exchange::Websocket.new( keepalive: true)
websocket.match do |resp|
  #  puts resp
  case resp.product_id
  when "BTC-USD"
    redis.set("spot_BTC_USD", resp.price)
    #p "BTC Spot Rate: $ %.2f" % resp.price
  when "ETH-USD"
    redis.set("spot_ETH_USD", resp.price)
    #p "ETH Spot Rate: $ %.2f" % resp.price
  when "LTC-USD"
    redis.set("spot_LTC_USD", resp.price)
    #p "LTC Spot Rate: $ %.2f" % resp.price
  when "ETH-BTC"
    redis.set("spot_ETH_BTC", resp.price)
    #p "LTC Spot Rate: $ %.2f" % resp.price
  when "LTC-BTC"
    redis.set("spot_LTC_BTC", resp.price)
    #p "LTC Spot Rate: $ %.2f" % resp.price
  end
  #puts "."
  puts "$%.2f" % redis.get("spot_BTC_USD") + " | " + "$%.2f" % redis.get("spot_ETH_USD") + " | " + "$%.2f" % redis.get("spot_LTC_USD") + " | " + "Ƀ%.5f" % redis.get("spot_ETH_BTC") + " | " + "Ƀ%.5f" % redis.get("spot_LTC_BTC")
end

# websocket.message do |resp|
#   if resp["type"] == "snapshot" && resp["product_id"] == "BTC-USD"
#     puts "building snapshot"
#     resp["bids"].each do |bid|
#       bids['%.2f' % bid[0]] = bid[1]
#     end
#     resp["asks"].each do |ask|
#       asks['%.2f' % ask[0]] = ask[1]
#     end
#     # binding.pry

#   end
#   if resp["type"] == "l2update" && resp["product_id"] == "BTC-USD"
#     #puts "updating order book"
#     resp.changes.each do |change|
#       case change[0]
#       when "buy"
#         bids['%.2f' % change[1]] = '%.2f' % change[2]

#       when "sell"
#         asks['%.2f' % change[1]] = '%.2f' % change[2]
#       end
#     end
#   end
# end
#binding.pry

EventMachine::run {
  websocket.start!

  EventMachine::start_server "127.0.0.1", 8081, EchoServer
  puts 'running echo server on 8081'


}
