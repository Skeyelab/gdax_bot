# frozen_string_literal: true

class Menus < GdaxBot
  def self.main_menu
    redis = Redis.new

    loop do
      prompt = TTY::Prompt.new
      choice = prompt.select('Choose your destiny?') do |menu|
        menu.enum '.'

        # menu.choice 'Open and Close Order', 'open_and_close'
        menu.choice 'Trailing Stop', 'trailing_stop'
        menu.choice 'View Data Stream', 'view_websocket'
        menu.choice 'Prompt', 'prompt'
        menu.choice 'Balance Portfolio', 'balance_portfolio'
        menu.choice 'Exit', 'exit'
      end

      case choice
      when 'exit'
        abort
      when 'prompt'
        rest_api = Coinbase::Pro::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])

        binding.pry
      when 'view_websocket'
        view_websocket
      when 'trailing_stop'
        trailing_stop_menu
      when 'balance_portfolio'
        show_splits
        set_splits unless prompt.no?('Set splits?')
        redis.set('balanceLoop', 'true')
        balLoop
      end
    end
  end

  def self.show_splits
    redis = Redis.new
    puts "BTC: #{redis.get('BTC_split')}"
    puts "LTC: #{redis.get('LTC_split')}"
    puts "ETH: #{redis.get('ETH_split')}"
    puts "BCH: #{redis.get('BCH_split')}"
    puts "LINK: #{redis.get('LINK_split')}"
    puts "USD: #{(1.0 - (redis.get('LTC_split').to_f + redis.get('BCH_split').to_f + redis.get('BTC_split').to_f + redis.get('ETH_split').to_f + redis.get('LINK_split').to_f)).round(2)}"
  end

  def self.set_splits
    prompt = TTY::Prompt.new
    redis = Redis.new

    btc_split = prompt.ask('BTC:', default: redis.get('BTC_split')).to_f
    redis.set('BTC_split', btc_split)

    ltc_split = prompt.ask('LTC:', default: redis.get('LTC_split')).to_f
    redis.set('LTC_split', ltc_split)

    eth_split = prompt.ask('ETH:', default: redis.get('ETH_split')).to_f
    redis.set('ETH_split', eth_split)

    bch_split = prompt.ask('BCH:', default: redis.get('BCH_split')).to_f
    redis.set('BCH_split', bch_split)

    # xrp_split = prompt.ask('XRP:', default: 0.1).to_f
    # redis.set('XRP_split', xrp_split)
    # redis.set('spread', 0.002)
    link_split = prompt.ask('LINK:', default: redis.get('LINK_split')).to_f
    redis.set('LINK_split', link_split)
  end

  def self.trailing_stop_menu
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

  def self.select_recent_order_menu(pair)
    puts 'Please wait, building menu.'
    orders = []
    rest_api = Coinbase::Pro::Client.new(
      ENV['GDAX_TOKEN'],
      ENV['GDAX_SECRET'],
      ENV['GDAX_PW']
    )

    rest_api.orders(status: 'done') do |resp|
      resp.each do |order|
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
end
