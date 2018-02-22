require 'rubygems'
require 'bundler'
Bundler.require
Dotenv.load
system('clear')
Dir["./inc/*.rb"].each {|file| require file }


# rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])

# rest_api.accounts do |resp|
#   resp.each do |account|
#     p "#{account.id}: %.8f #{account.currency} available for trading" % account.available
#   end
# end

def pair_menu
  prompt = TTY::Prompt.new
  choices = %w(LTC-BTC ETH-BTC BCH-BTC BTC-USD ETH-USD LTC-USD BCH-USD)
  return prompt.enum_select("Pair?", choices, per_page: 7)
end

def gdax_bot
  redis = Redis.new

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
      #choices = %w(LTC-BTC ETH-BTC BCH-BTC BTC-USD ETH-USD LTC-USD BCH-USD)
      #pair = prompt.enum_select("Pair?", choices, per_page: 7)
      pair = pair_menu
      open_price = prompt.ask('Open Price?', default: (redis.get("spot_#{pair.split('-')[0]}_#{pair.split('-')[1]}").to_f).round_down(5)).to_f
      percent_of_portfolio = prompt.ask('Percent of portfolio to use?', default: 10.0).to_f
      profit = prompt.ask('Profit Goal %?', default: 1.0).to_f
      t_stop = prompt.ask('Trailing Stop %?', default: 0.5).to_f
      stop_percent = prompt.ask('Initial Stop Loss %?', default: 1.0).to_f
      trailing_stop(open_price, percent_of_portfolio/100, pair, profit, t_stop, stop_percent)
    end
  end

end

begin
  gdax_bot
rescue SystemExit => e
  abort
rescue Exception => e
  puts "Error: #{e}"
  gdax_bot
ensure
  system('stty -raw echo')
end
