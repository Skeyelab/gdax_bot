# frozen_string_literal: true

def market_skim(times = 2, pair = 'ETH-BTC', percent_of_portfolio = 0.99, down = 0.00002, up = 0.00002)
  redis = Redis.new
  # rest_api = Coinbase::Pro::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'], product_id: pair)
  # while true
  times.times do
    spot = format('%.5f', redis.get("spot_#{pair.split('-')[0]}_#{pair.split('-')[1]}"))
    puts "Spot: #{spot}"
    begin
      open_position((spot.to_f - down).round_down(5), (spot.to_f + up).round_down(5), percent_of_portfolio, pair)
    rescue StandardError => exception
      puts exception
      break
    end
    sleep 1
  end
end
