def trailing_start_menu

  prompt = TTY::Prompt.new
  redis = Redis.new

  pair = pair_menu

  if prompt.yes?('Create new order?')
    existing = false
    open_price = prompt.ask('Open Price?', default: (redis.get("spot_#{pair.split('-')[0]}_#{pair.split('-')[1]}").to_f).round_down(5)).to_f
    percent_of_portfolio = prompt.ask('Percent of portfolio to use?', default: 10.0).to_f
  else
    existing = select_recent_order_menu(pair)
    open_price = existing["price"].to_f
    percent_of_portfolio = 10
  end


  profit = prompt.ask('Profit Goal %?', default: 1.0).to_f
  t_stop = prompt.ask('Trailing Stop %?', default: 0.5).to_f
  stop_percent = prompt.ask('Initial Stop Loss %?', default: 10.0).to_f

  trailing_stop(open_price, percent_of_portfolio/100, pair, profit, t_stop, stop_percent, existing)
end

def select_recent_order_menu(pair)
  puts "Please wait, building menu."
  orders = []
  rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])
  rest_api.orders(status: "done") do |resp|
    resp.each do |order|
      if order["product_id"] == pair and order["done_reason"] == "filled"
        orders << order
      end
    end
  end

  recent_orders = []

  prompt = TTY::Prompt.new
  selected_order =   prompt.select("Trail which order?", per_page: 10) do |menu|
    menu.enum '.'
    orders[0..4].each do |order|
      menu.choice "#{order["size"]} @ #{order["price"]}", order
    end
  end
  return selected_order
end
