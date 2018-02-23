def trailing_start_menu

  prompt = TTY::Prompt.new
  redis = Redis.new

  pair = pair_menu
  open_price = prompt.ask('Open Price?', default: (redis.get("spot_#{pair.split('-')[0]}_#{pair.split('-')[1]}").to_f).round_down(5)).to_f
  percent_of_portfolio = prompt.ask('Percent of portfolio to use?', default: 10.0).to_f
  profit = prompt.ask('Profit Goal %?', default: 1.0).to_f
  t_stop = prompt.ask('Trailing Stop %?', default: 0.5).to_f
  stop_percent = prompt.ask('Initial Stop Loss %?', default: 10.0).to_f
  trailing_stop(open_price, percent_of_portfolio/100, pair, profit, t_stop, stop_percent)
end
