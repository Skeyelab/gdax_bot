def watch_order(order)
  redis = Redis.new

  pair = order.product_id

  rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'], product_id: pair )

  spinner = TTY::Spinner.new("[:spinner] Checking on #{order.side} order - Current spread: :spread",clear: true)

  loop do
    begin
      spot = "%.5f" % redis.get("spot_#{pair.split('-')[0]}_#{pair.split('-')[1]}")
      spinner.update(spread: "%.5f" % (spot.to_f - order.price))
      spinner.spin
      rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'], product_id: pair )
      if rest_api.order(order.id)["settled"]
        spinner.success('(successful)')
        return true
      else
        sleep 1.0/3.0
        spinner.spin
      end

    rescue Coinbase::Exchange::NotFoundError => e
      if e.message == "{\"message\":\"NotFound\"}"
        spinner.error("Order not found")
        sleep 1
        return false
      end
    rescue Exception => e
      puts "Error, retrying"
      puts e
      sleep 1
      retry
    end
  end
end
