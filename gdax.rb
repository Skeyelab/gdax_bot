require 'rubygems'
require 'bundler'
Bundler.require
Dotenv.load
system('clear')
Dir["./inc/*.rb"].each {|file| require file }

redis = Redis.new

# rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])

# rest_api.accounts do |resp|
#   resp.each do |account|
#     p "#{account.id}: %.8f #{account.currency} available for trading" % account.available
#   end
# end

loop do

  prompt = TTY::Prompt.new
  choice = prompt.select("Choose your destiny?") do |menu|
    menu.enum '.'

    #menu.choice 'Open and Close Order', 'open_and_close'
    menu.choice 'Trailing Stop', 'trailing_stop'

    menu.choice 'Prompt', 'prompt'
    menu.choice 'Exit', 'exit'
  end

  case choice
  when 'exit'
    abort
  when 'prompt'
    binding.pry
  when 'trailing_stop'
    pair = prompt.ask('Pair?', default: 'LTC-BTC')
    open_price = prompt.ask('Open Price?', default: redis.get("spot_#{pair.split('-')[0]}_#{pair.split('-')[1]}").to_f - 0.00001)
    percent_of_portfolio = prompt.ask('Percent of portfolio to use?', default: 10.0)
    profit = prompt.ask('Profit Goal %?', default: 1.0)
    t_stop = prompt.ask('Trailing Stop %?', default: 0.5)
    stop_percent = prompt.ask('Initial Stop Loss %?', default: 1.0)
    trailing_stop(open_price, percent_of_portfolio, pair, profit, t_stop, stop_percent)
  end
end
