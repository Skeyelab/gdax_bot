def trailing_stop (open_price, percent_of_portfolio, pair="BTC-USD", profit=1.0, t_stop=0.5, stop_percent=1.0 )

  redis = Redis.new

  stop_price = (open_price - (open_price * stop_percent/100)).round_down(5)
  t_stop_price = (open_price - (open_price * t_stop/100)).round_down(5)

  rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'], product_id: pair )

  start = Time.now

  #binding.pry
  order_size = (bal(pair) * percent_of_portfolio)/open_price
  #open_order = rest_api.buy(order_size.round_down(8), open_price)

  #watch_order(open_order)
  #spinner = TTY::Spinner.new("[:spinner] #{order.side.capitalize}ing :size :p1 for :price :p2 - Current spread: :spread", format: :bouncing_ball)

  profit_made = false
  stop_loss_reached = false

	loop do 
		spot = redis.get("spot_#{pair.split('-')[0]}_#{pair.split('-')[1]}").to_f
		current_profit_percentage = Percentage.change(open_price, spot).to_f

		if current_profit_percentage >= profit
			puts "profit margin reached"
			profit_made = true
			break
		elsif (-stop_percent) > current_profit_percentage.to_f 
			puts "Stop loss reached"
			stop_loss_reached = true
			break
		else
			current_profit = "%.5f" % (spot - open_price)
			puts "current profit: #{current_profit_percentage.round_down(4)}% | profit goal: #{profit}% | stop %: #{stop_percent} | stop price: #{stop_price} | open: #{open_price} | current price: #{spot} | actual profit: #{current_profit}"
			#sleep 1
		end
	end 

	if stop_loss_reached 
		spot = redis.get("spot_#{pair.split('-')[0]}_#{pair.split('-')[1]}").to_f
		puts "Selling at #{spot - 0.00001}"
		rest_api.sell(order_size.round_down(8), spot - 0.00001)
		puts "Sold"
		return
	end

	
	last_spot = redis.get("spot_#{pair.split('-')[0]}_#{pair.split('-')[1]}").to_f
	loop do
		
  		spot = redis.get("spot_#{pair.split('-')[0]}_#{pair.split('-')[1]}").to_f
  		puts "Trailing Stop: #{t_stop_price} | Spot: #{spot}"

		if spot < t_stop_price
			puts "Trailing stop hit"
			puts "Sold at #{spot - 0.00001}"

			#rest_api.sell(order_size.round_down(8), spot - 0.00001)
			break
		else
			last_spot = spot
		end

end

end_time = Time.now
puts "#{Percentage.change(open_price,close_price).to_f}% gain in #{humanize((end_time - start).to_i)}."

end
