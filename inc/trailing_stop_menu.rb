# frozen_string_literal: true

def trailing_start_menu
  prompt = TTY::Prompt.new
  redis = Redis.new

  unless checkForPausedJob('ts')

    pair = pair_menu
    if pair == 'Back'
      return
    end

    if prompt.yes?('Create new order?')
      existing = false

    else
      existing = select_recent_order_menu(pair)
      if existing == false
        return
      end
      open_price = existing['price'].to_f
      percent_of_portfolio = 10
    end

    profit = prompt.ask('Profit Goal %?', default: 1.0).to_f
    t_stop = prompt.ask('Trailing Stop %?', default: 0.5).to_f
    stop_percent = prompt.ask('Initial Stop Loss %?', default: 10.0).to_f

    unless existing
      percent_of_portfolio = prompt.ask('Percent of portfolio to use?', default: 10.0).to_f
      open_price = prompt.ask('Open Price?', default: (redis.get("spot_#{pair.split('-')[0]}_#{pair.split('-')[1]}").to_f).round_down(5)).to_f
    end

    trailing_stop(open_price, percent_of_portfolio/100, pair, profit, t_stop, stop_percent, existing)
  else
    puts 'Paused job found, resuming.'
    puts ''
    puts "Pair: #{checkForPausedJob('ts')['pair'].green}"
    puts "Open: #{checkForPausedJob('ts')['existing']['size'].to_s.green} @ #{checkForPausedJob('ts')['existing']['price'].to_s.green}"
    puts "Profit Goal %? #{checkForPausedJob('ts')['profit'].to_s.green}"
    puts "Trailing Stop %? #{checkForPausedJob('ts')['t_stop'].to_s.green}"
    puts "Initial Stop Loss %? #{checkForPausedJob('ts')['stop'].to_s.green}"
    trailing_stop(checkForPausedJob('ts')['open_price'], checkForPausedJob('ts')['percent_of_portfolio'], checkForPausedJob('ts')['pair'], checkForPausedJob('ts')['profit'], checkForPausedJob('ts')['t_stop'], checkForPausedJob('ts')['stop_percent'], checkForPausedJob('ts')['existing'])

  end
end

def select_recent_order_menu(pair)
  puts 'Please wait, building menu.'
  orders = []
  rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])
  rest_api.orders(status: 'done') do |resp|
    resp.each do |order|
      if order['product_id'] == pair and order['done_reason'] == 'filled' and order['side'] == 'buy'
        orders << order
       end
    end
  end

  recent_orders = []

  prompt = TTY::Prompt.new
  selected_order =   prompt.select('Trail which order?', per_page: 10) do |menu|
    menu.enum '.'
    orders[0..4].each do |order|
      menu.choice "#{order["size"]} @ #{order["price"]}", order
    end
    menu.choice 'Manual'
    menu.choice 'Back'
  end
  if selected_order == 'Back'
    return false
  elsif selected_order == 'Manual'
    selected_order = {}
    selected_order['size'] = prompt.ask('Order size?')
    selected_order['price'] = prompt.ask('Open price?')
  end
  return selected_order
end
