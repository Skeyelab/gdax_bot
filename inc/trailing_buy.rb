
# frozen_string_literal: true

def trailing_buy(_percent_of_portfolio, pair = 'LTC-USD')
  redis = Redis.new

  last_spot = redis.get("spot_#{pair.split('-')[0]}_#{pair.split('-')[1]}").to_f
  # rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'], product_id: pair)

  # color = :light_yellow
  # bg_color = :default

  market_low = last_spot
  spot_array = []

  loop do
    sleep 1.0 / 100
    spot = redis.get("spot_#{pair.split('-')[0]}_#{pair.split('-')[1]}").to_f
    spot_array << spot
    spot_array = spot_array.last(500)
    spot_sma = spot_array.sma.round(5)

    if spot_sma < market_low
      market_low = spot
      # t_stop_price = spot - (spot * t_stop / 100)
    end
    puts "#{market_low} | #{spot} | #{spot_sma}"
  end
  # order_size = (bal(pair) * percent_of_portfolio) / redis.get("spot_#{pair.split('-')[0]}_#{pair.split('-')[1]}").to_f
end
