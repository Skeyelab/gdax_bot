def close_position (order, price)
  rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'], product_id: order.product_id )

  if !watch_order(order)
    return
  end
  order_size = order.size


  puts ""


  if order["side"] == "buy"
    #puts "Selling #{order_size.to_f} #{order['product_id'].split('-')[0]} @ $#{price}"

    begin
      sell_order = rest_api.sell(order_size,price)
      #puts "Sell order ID is #{sell_order.id}"
      #puts sell_order
      watch_order sell_order
      return

    rescue Coinbase::Exchange::NotFoundError => e
      if e.message == "{\"message\":\"NotFound\"}"
        puts "Order not found"
        sleep 1
        return
      end

    rescue Exception => e
      #binding.pry
    end


    # elsif order["side"] == "sell"
    #   puts "Selling #{order_size} #{order_size} #{order['product_id'].split('-')[0]} @ $#{price}"
    #   begin
    #     sell_order = rest_api.buy(order_size,price) do |resp|
    #       puts "Sell order ID is #{resp.id}"

    #       return sell_order
    #     end
    #   rescue Exception => e
    #     binding.pry
    #   end
    print "\a"

  end

end
