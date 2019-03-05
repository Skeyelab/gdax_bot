def buy(pair, price, order_size)
	rest_api = Coinbase::Exchange::Client.new(
	  ENV['GDAX_TOKEN'],
	  ENV['GDAX_SECRET'],
	  ENV['GDAX_PW'],
	  product_id: pair
	)

	begin
		buy_order = rest_api.buy(order_size, price)

	rescue Coinbase::Exchange::NotFoundError => e
		if e.message == '{"message":"NotFound"}'
			puts 'Order not found'
			sleep 1
			return sell_order
		end
	rescue StandardError => e
		puts e
	end
	# binding.pry
end