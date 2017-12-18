require 'rubygems'
require 'bundler'
Bundler.require
Dotenv.load

Dir["./inc/*.rb"].each {|file| require file }

redis = Redis.new

rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])

rest_api.accounts do |resp|
  resp.each do |account|
    p "#{account.id}: %.8f #{account.currency} available for trading" % account.available
  end
end

binding.pry
