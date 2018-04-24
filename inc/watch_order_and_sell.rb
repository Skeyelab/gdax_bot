def watch_order_and_sell (order, sell_level)
  rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])

  puts "Checking on order #{order.id}"
  loop do
    begin
      rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])
      if rest_api.order(order.id)["settled"]
        break
      else
        sleep 1.0/3.0
        print "."
      end
    rescue Exception => e
      puts "Error, retrying"
      sleep 1
      retry
    end
  end
  puts ""
  proceeds = (order["price"].to_f * order["size"].to_f).round_down(2)
  order_size = (proceeds/sell_level).round_down(8)

  order_size = (bal(pair) * percent_of_portfolio)/open_price

  puts "Selling #{order_size} BTC @ $#{sell_level}"

  rest_api.sell(order_size,sell_level) do |resp|
    puts "Order ID is #{resp.id}"
  end
end
