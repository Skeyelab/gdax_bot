# frozen_string_literal: true

def trailing_stop_menu
  prompt = TTY::Prompt.new
  redis = Redis.new

  if check_for_paused_job('ts')
    puts 'Paused job found, resuming.'
    puts ''
    puts "Pair: #{check_for_paused_job('ts')['pair'].green}"
    puts "Open: #{check_for_paused_job('ts')['existing']['size'].to_s.green} @ #{check_for_paused_job('ts')['existing']['price'].to_s.green}"
    puts "Profit Goal %? #{check_for_paused_job('ts')['profit'].to_s.green}"
    puts "Trailing Stop %? #{check_for_paused_job('ts')['t_stop'].to_s.green}"
    puts "Initial Stop Loss %? #{check_for_paused_job('ts')['stop'].to_s.green}"
    trailing_stop(check_for_paused_job('ts')['open_price'], check_for_paused_job('ts')['percent_of_portfolio'],
                  check_for_paused_job('ts')['pair'], check_for_paused_job('ts')['profit'], check_for_paused_job('ts')['t_stop'], check_for_paused_job('ts')['stop_percent'], check_for_paused_job('ts')['existing'])

  else

    pair = pair_menu
    return if pair == 'Back'

    if prompt.yes?('Create new order?')
      existing = false

    else
      existing = select_recent_order_menu(pair)
      return if existing == false

      open_price = existing['price'].to_f
      percent_of_portfolio = 10
    end

    profit = prompt.ask('Profit Goal %?', default: 1.1).to_f
    t_stop = prompt.ask('Trailing Stop %?', default: 0.2).to_f
    stop_percent = prompt.ask('Initial Stop Loss %?', default: 10.0).to_f

    unless existing
      percent_of_portfolio = prompt.ask('Percent of portfolio to use?', default: 10.0).to_f
      open_price = prompt.ask('Open Price?',
                              default: redis.get("spot_#{pair.split('-')[0]}_#{pair.split('-')[1]}").to_f.round_down(5)).to_f
    end

    trailing_stop(open_price, percent_of_portfolio / 100, pair, profit, t_stop, stop_percent, existing)
  end
end

def select_recent_order_menu(pair)
  puts 'Please wait, building menu.'
  orders = []
  rest_api = Coinbase::Pro::Client.new(
    ENV['GDAX_TOKEN'],
    ENV['GDAX_SECRET'],
    ENV['GDAX_PW']
  )

  rest_api.orders(status: 'done') do |resp|
    sleep 1
    resp.each do |order|
      sleep 1
      if (order['product_id'] == pair) && (order['done_reason'] == 'filled') && (order['side'] == 'buy')
        orders << order
      end
    end
  end

  # recent_orders = []

  prompt = TTY::Prompt.new
  selected_order = prompt.select('Trail which order?', per_page: 10) do |menu|
    menu.enum '.'
    orders[0..4].each do |order|
      menu.choice "#{order['size']} @ #{order['price']}", order
    end
    menu.choice 'Manual'
    menu.choice 'Back'
  end
  case selected_order
  when 'Back'
    return false
  when 'Manual'
    selected_order = {}
    selected_order['size'] = prompt.ask('Order size?')
    selected_order['price'] = prompt.ask('Open price?')
  end

  selected_order
end
