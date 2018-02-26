def trailing_stop (open_price, percent_of_portfolio, pair="LTC-BTC", profit=0.5, t_stop=0.25, stop_percent=1.0,existing=false )

  redis = Redis.new

  last_spot = redis.get("spot_#{pair.split('-')[0]}_#{pair.split('-')[1]}").to_f
  stop_price = (open_price - (open_price * stop_percent/100)).round_down(5)
  profit_goal_price = (open_price + (open_price * profit/100)).round_down(5)
  t_stop_price = (profit_goal_price - (profit_goal_price * t_stop/100)).round_down(5)
  last_t_stop = t_stop_price
  rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'], product_id: pair )

  start = Time.now

  market_high = 0.0
  order_size = (bal(pair) * percent_of_portfolio)/open_price
  
  if existing
    order_size = existing["size"].to_f
  else  
    open_order = rest_api.buy(order_size.round_down(8), open_price)
    if watch_order(open_order) == false
      return false
    end 
  end

  profit_made = false
  stop_loss_reached = false
  spot_array = []

  loop do
    sleep 1.0/100
  spot = redis.get("spot_#{pair.split('-')[0]}_#{pair.split('-')[1]}").to_f
  current_profit_percentage = Percentage.change(open_price, spot).to_f
  spot_array << spot
  spot_array = spot_array.last(500)

  if stop_price > spot
    #elsif (-stop_percent) > current_profit_percentage.to_f
    puts "Stop loss reached"
    stop_loss_reached = true
    spot = redis.get("spot_#{pair.split('-')[0]}_#{pair.split('-')[1]}").to_f
    if !profit_made
      binding.pry
    end
    if pair.split('-')[1] == "USD"
      puts "Selling at #{spot - 0.01}"
      order =  rest_api.sell(order_size.round_down(8), (spot - 0.01).round_down(2))
    else
      puts "Selling at #{spot - 0.00001}"
      order =  rest_api.sell(order_size.round_down(8), (spot - 0.00001).round_down(8))
    end
    watch_order(order)
    puts "Sold"
    return
    #break
  end

  if spot >= profit_goal_price
    profit_made = true
  end

  if spot > market_high
    market_high = spot
    t_stop_price = spot - (spot * t_stop / 100)

  end

  if profit_made
    stop_price = t_stop_price

    print "* "
  end

  current_profit = "%.5f" % (spot - open_price)
  stop_distance = "%.5f" % (spot - stop_price)
  t_stop_distance = "%.5f" % (spot - t_stop_price)

  if spot < spot_array.sma.round(5)
    trend = "-"
  elsif spot > spot_array.sma.round(5)
    trend = "+"
  else
    trend = " "
  end


  puts "profit: #{current_profit_percentage.round_down(4)}%\t| profit #: #{current_profit}\t| profit % goal: #{profit}\t| profit goal: #{profit_goal_price}\t| open: #{open_price}\t| current: #{spot}\t| #{trend} | spot SMA: #{spot_array.sma.round(5)}\t| stop %: #{stop_percent}\t| stop: #{stop_price}\t| stop range: #{stop_distance}\t| t stop range: #{t_stop_distance} | market high: #{market_high}"
  #sleep 1
  last_spot = spot
  last_t_stop = t_stop_price
end
end
