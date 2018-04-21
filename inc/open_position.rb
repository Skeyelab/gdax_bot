def open_position(open_price, close_price, percent_of_portfolio, pair = 'BTC-USD' )
	 rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'], product_id: pair )

	 start = Time.now

	 # binding.pry
	 order_size = (bal(pair) * percent_of_portfolio) / open_price
	 open_order = rest_api.buy(order_size.round_down(8), open_price)
	 if close_position(open_order, close_price)
 		 end_time = Time.now
 		 puts "#{Percentage.change(open_price, close_price).to_f}% gain in #{humanize((end_time - start).to_i)}."
 	end
end
