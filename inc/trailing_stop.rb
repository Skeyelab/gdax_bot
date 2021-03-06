# frozen_string_literal: true

# @todo Refactor trailing_stop
# @body this code is messy
def trailing_stop(open_price, percent_of_portfolio, pair = 'LTC-BTC', profit = 0.5, t_stop = 0.25, stop_percent = 1.0, existing = false)
  File.delete('jobs/paused_ts.json') if check_for_paused_job('ts')

  redis = Redis.new

  last_spot = redis.get("spot_#{pair.split('-')[0]}_#{pair.split('-')[1]}").to_f
  stop_price = (open_price - (open_price * stop_percent / 100)).round_down(5)
  profit_goal_price = (open_price + (open_price * profit / 100)).round_down(5)
  t_stop_price = (profit_goal_price - (profit_goal_price * t_stop / 100)).round_down(5)
  last_t_stop = t_stop_price
  rest_api = Coinbase::Pro::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'], product_id: pair)

  color = :light_yellow
  bg_color = :default

  start = Time.now

  market_high = 0.0
  order_size = (bal(pair) * percent_of_portfolio) / open_price
  if existing
    order_size = existing['size'].to_f
  else
    open_order = rest_api.buy(order_size.round_down(8), open_price)
    # try_push_message(pair.to_s, 'Trailing Stop Buy Order Placed')
    return false if watch_order(open_order) == false

    order_size = open_order['size'].to_f
  end

  job_hash = {
    open_price: open_price,
    percent_of_portfolio: percent_of_portfolio,
    pair: pair,
    profit: profit,
    t_stop: t_stop,
    stop_percent: stop_percent,
    existing: {
      'price' => open_price,
      'size' => order_size
    }
  }

  profit_made = false
  stop_loss_reached = false
  spot_array = []

  # puts "Profit Goal %: #{'%.2f' % profit}"
  print "Profit Goal #{pair.split('-')[1]}: "
  puts format('%.5f', profit_goal_price).to_s.green
  # puts "Open: #{'%.5f' % open_price}"
  # puts "Hard Stop %: #{'%.2f' % stop_percent}"
  puts ''
  puts "Press 'c' to cancel, 'p' to pause."
  # puts "Trailing Stop %: #{'%.2f' % t_stop}"
  spinner = TTY::Spinner.new(
    "[:spinner] Profit %: :p1 | Profit #{pair.split('-')[1]}: :p2 | Current Price: :spot |:trend| SMA: :sma | Stop: :stop | Stop Distance: :dist | SMA Dist: :s2", interval: 5, format: :bouncing_ball, hide_cursor: true
  )

  # try_push_message(pair.to_s, 'Trailing Stop Started', 'pushover')

  i = 0
  loop do
    i += 1
    sleep 1.0 / 100
    spot = redis.get("spot_#{pair.split('-')[0]}_#{pair.split('-')[1]}").to_f
    spot_array << spot
    spot_array = spot_array.last(1500)
    spot_sma = spot_array.sma.round(5)
    current_profit_percentage = Percentage.change(open_price, spot_sma).to_f

    if stop_price > spot_sma
      # elsif (-stop_percent) > current_profit_percentage.to_f
      puts 'Stop loss reached'
      stop_loss_reached = true
      spot = redis.get("spot_#{pair.split('-')[0]}_#{pair.split('-')[1]}").to_f
      binding.pry unless profit_made

      sell(pair, order_size)
      # spot = redis.get("spot_#{pair.split("-")[0]}_#{pair.split("-")[1]}").to_f
      # if pair.split("-")[1] == "USD"
      #   puts "Selling at #{spot - 0.01}"
      #   order = rest_api.sell(order_size.round_down(8), (spot - 0.01).round_down(2), type: "market")
      # else
      #   puts "Selling at #{spot - 0.00001}"
      #   order = rest_api.sell(order_size.round_down(8), (spot - 0.00001).round_down(8), type: "market")
      # end
      # sleep 1
      # watch_order(order) unless rest_api.order(order.id).settled
      # try_push_message(pair.to_s, "Trailing Stop Completed", "cashregister")
      # puts "Sold"

      return true
      # break
    end

    if (spot_sma >= profit_goal_price) && (profit_made == false)
      profit_made = true
      # try_push_message(pair.to_s, 'Profit Goal Reached', 'cashregister')
    end

    if spot > market_high
      market_high = spot
      t_stop_price = spot - (spot * t_stop / 100)

    end

    if profit_made
      stop_price = t_stop_price
      color = :light_white
      bg_color = :green
    end

    current_profit = ((spot_sma - open_price) * order_size).round(5)
    stop_distance = format('%.5f', (spot_sma - stop_price))
    # t_stop_distance = format('%.5f', (spot_sma - t_stop_price))

    trend = if spot < spot_sma
              ' - '.white.on_red.bold
            elsif spot > spot_sma
              ' + '.white.on_green.bold
            else
              '   '.white
            end

    system('stty raw -echo')
    k = GetKey.getkey
    system('stty -raw echo')

    case k
    when 115
      sell(pair, order_size)
      return true
    when 99
      spinner.error('(Canceled)')
      return false
    when 112
      spinner.stop('(Paused)')
      File.open('jobs/paused_ts.json', 'w') do |f|
        f.write(job_hash.to_json)
      end
      return false
    end

    # print "profit: #{'%.5f' % current_profit_percentage.round_down(5)}% | profit #{pair.split('-')[1]}: #{'%.5f' % current_profit} | profit % goal: #{'%.2f' % profit} | profit goal: #{'%.5f' % profit_goal_price} | open: #{'%.5f' % open_price} | current: #{'%.5f' % spot} |".colorize(color)
    # print trend
    # puts  "| spot SMA: #{'%.5f' % spot_sma} | stop %: #{'%.2f' % stop_percent} | stop: #{'%.5f' % stop_price} | stop range: #{'%.5f' % stop_distance} | t stop range: #{'%.5f' % t_stop_distance} | market high: #{'%.5f' % market_high}".colorize(color)

    if (i % 5).zero?
      spinner.update(p1: format('%.5f', current_profit_percentage.round_down(5)).to_s.colorize(color: color,
                                                                                               background: bg_color))
      spinner.update(p2: format('%.5f', current_profit).to_s)
      spinner.update(spot: format('%.5f', spot).to_s)
      spinner.update(trend: trend.to_s)
      spinner.update(sma: format('%.5f', spot_sma).to_s)
      spinner.update(stop: format('%.5f', stop_price).to_s)
      spinner.update(dist: format('%.5f', stop_distance).to_s)
      spinner.update(s2: format('%.5f', (spot - spot_sma).abs).to_s)
      spinner.spin
    end
    # sleep 1
    last_spot = spot
    last_t_stop = t_stop_price
  end
end

def sell(pair, order_size)
  rest_api = Coinbase::Pro::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'], product_id: pair)
  redis = Redis.new
  puts ''
  puts 'Selling'
  spot = redis.get("spot_#{pair.split('-')[0]}_#{pair.split('-')[1]}").to_f
  if pair != 'BCH-BTC'
    if pair.split('-')[1] == 'USD'
      puts "Selling at #{spot - 0.01}"
      order = rest_api.sell(order_size.round_down(8), (spot - 0.01).round_down(2), type: 'market')
    else
      puts "Selling at #{spot - 0.00001}"
      order = rest_api.sell(order_size.round_down(8), (spot - 0.00001).round_down(8), type: 'market')
    end

  else
    if pair.split('-')[1] == 'USD'
      puts "Selling at #{spot - 0.01}"
      order = rest_api.sell(order_size.round_down(8), (spot - 0.01).round_down(2), type: 'limit')
    else
      puts "Selling at #{spot - 0.00001}"
      order = rest_api.sell(order_size.round_down(8), (spot - 0.00001).round_down(8), type: 'limit')
    end
    sleep 1
    watch_order(order) unless rest_api.order(order.id).settled
    # try_push_message(pair.to_s, 'Trailing Stop Completed', 'cashregister')
    puts 'Sold'
  end
end
