# frozen_string_literal: true

def blah_method
  puts 'blah'
end

def humanize(secs)
  [[60, :seconds], [60, :minutes], [24, :hours], [1000, :days]].map do |count, name|
    if secs.positive?
      secs, n = secs.divmod(count)
      "#{n.to_i} #{name}"
    end
  end.compact.reverse.join(' ')
end

# adds percent_of to Numeric class
class Numeric
  def percent_of(num)
    to_f / num.to_f * 100.0
  end
end

# adds round_down to Float class
class Float
  def round_down(num = 0)
    num < 1 ? to_i.to_f : (self - 0.5 / 10**num).round(num)
  end
end

def check_for_paused_job(type)
  if File.file?("jobs/paused_#{type}.json")
    file = File.read("jobs/paused_#{type}.json")
    paused_job = JSON.parse(file)
    paused_job
  else
    false
  end
end

def init_env
  return true if File.file?('.env')

  puts 'No .env file found'
  abort
  # if no .env file, create it
end

def init_redis
  begin
    redis = Redis.new
  rescue StandardError => e
    Raven.capture_exception(e)
    puts e
  end

  redis.set('spot_BTC_USD', 0) unless redis.get('spot_BTC_USD')
  redis.set('spot_ETH_USD', 0) unless redis.get('spot_ETH_USD')
  redis.set('spot_LTC_USD', 0) unless redis.get('spot_LTC_USD')
  redis.set('spot_ETH_BTC', 0) unless redis.get('spot_ETH_BTC')
  redis.set('spot_LTC_BTC', 0) unless redis.get('spot_LTC_BTC')
  redis.set('spot_BCH_USD', 0) unless redis.get('spot_BCH_USD')
  redis.set('spot_BCH_BTC', 0) unless redis.get('spot_BCH_BTC')
  redis.set('spot_ETC_BTC', 0) unless redis.get('spot_ETC_BTC')
  redis.set('spot_ETC_USD', 0) unless redis.get('spot_ETC_USD')
  redis.set('spot_ZRX_BTC', 0) unless redis.get('spot_ZRX_BTC')
  redis.set('spot_XRP_USD', 0) unless redis.get('spot_XRP_USD')
  redis.set('spot_LINK_USD', 0) unless redis.get('spot_LINK_USD')

  redis.set('BTC_split', 0.1) unless redis.get('BTC_split')
  redis.set('LTC_split', 0.1) unless redis.get('LTC_split')
  redis.set('ETH_split', 0.1) unless redis.get('ETH_split')
  redis.set('BCH_split', 0.1) unless redis.get('BCH_split')
  redis.set('XRP_split', 0.1) unless redis.get('XRP_split')
  redis.set('LINK_split', 0.0) unless redis.get('LINK_split')

  redis.set('XRP_min', 5) unless redis.get('XRP_min')
  redis.set('ProfitTo', 10_000) unless redis.get('ProfitTo')
  redis.set('takeProfits', 'false') unless redis.get('takeProfits')
end

def bump_splits(bump = 0.01)
  redis = Redis.new
  redis.set('BTC_split', redis.get('BTC_split').to_f + bump)
  redis.set('LTC_split', redis.get('LTC_split').to_f + bump)
  redis.set('ETH_split', redis.get('ETH_split').to_f + bump)
  redis.set('BCH_split', redis.get('BCH_split').to_f + bump)
  redis.set('XRP_split', redis.get('XRP_split').to_f + bump)
  redis.set('LINK_split', redis.get('LINK_split').to_f + bump)
end

def try_push_message(message, title, sound = 'none')
  if ENV['PUSHOVER_USER'] == ''
    false
  else
    message = Pushover::Message.create(message: message, title: title, user: ENV['PUSHOVER_USER'], token: 'a1ny247b6atuu67s9vc8g4djgm3c3p', sound: sound)
    response = message.push
    true
  end
end

def usd_bal
  rest_api = Coinbase::Pro::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])
  begin
    rest_api.accounts do |resp|
      resp.each do |account|
        return account.available.to_f - 0.01 if account.currency == 'USD'
      end
    end
  rescue Coinbase::Pro::RateLimitError => e
    sleep 1
    retry
  rescue Coinbase::Pro::BadRequestError => e
    Raven.capture_exception(e) unless e.message.include? 'size'
  rescue StandardError => e
    Raven.capture_exception(e)
    # puts e
  end
end

def decimals(abc)
  num = 0
  while abc != abc.to_i
    num += 1
    abc *= 10
  end
  num
end

def showPotentialOrders
  balances[0..5].each do |b|
    puts b['BorS']['size'].to_f
  end
end

def bal(pair = 'BTC-USD')
  rest_api = Coinbase::Pro::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])

  begin
    rest_api.accounts do |resp|
      resp.each do |account|
        return account.available.to_f.round_down(8) if account.currency == pair.split('-')[1]
      end
    end
  rescue Coinbase::Pro::BadRequestError => e
    if e.message == 'request timestamp expired'
      sleep 1
      retry
    else
      Raven.capture_exception(e)
    end
  end
end

def balanceInUsd(currency)
  rest_api = Coinbase::Pro::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])
  redis = Redis.new

  begin
    rest_api.accounts do |resp|
      resp.each do |account|
        spot = format('%.5f', redis.get("spot_#{currency}_USD")).to_f
        begin
          return((account.available.to_f.round_down(8) + account.hold.to_f.round_down(8)) * spot).round_down(2) if account.currency == currency
        rescue Coinbase::Pro::RateLimitError, Net::OpenTimeout => e
          sleep 1
          retry
        rescue Coinbase::Pro::BadRequestError => e
          Raven.capture_exception(e) unless e.message == 'request timestamp expired'
        rescue Exception => e
          Raven.capture_exception(e)
          puts e
          return 0
        end
      end
    end
  rescue Coinbase::Pro::BadRequestError => e
    if e.message == 'request timestamp expired'
      sleep 1
      retry
    else
      Raven.capture_exception(e)
    end
  end
end

def totalBalanceInUsd
  rest_api = Coinbase::Pro::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])
  redis = Redis.new
  total = 0
  rest_api.accounts do |resp|
    resp.each do |account|
      spot = format('%.5f', redis.get("spot_#{account.currency}_USD")).to_f
      total += ((account.available.to_f.round_down(8) + account.hold.to_f.round_down(8)) * spot).round_down(2)
    rescue Net::OpenTimeout => e
      sleep 1
      retry
    rescue TypeError
    rescue Exception => e
      Raven.capture_exception(e)
      # puts e
    end
  end
  (total + usd_bal).round_down(2)
end

def takeProfitTo(bottom)
  if totalBalanceInUsd > bottom
    withdrawal = totalBalanceInUsd - bottom
    Cb.withdraw withdrawal.round(2)
#	puts "withdrew"
  end
end

def replenishUpTo(top)
  if top > totalBalanceInUsd
    depositAmt = top - totalBalanceInUsd
    Cb.deposit depositAmt.round(2)
  end
end

# def cb_withdraw(dollars)
#   rest_api = Coinbase::Pro::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])
#   rest_api.coinbase_withdrawal(dollars, 'USD', ENV['CB_WALLET_ID'])
# end

# def cb_deposit(dollars)
#   rest_api = Coinbase::Pro::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])
#   rest_api.coinbase_deposit(dollars, 'USD', ENV['CB_WALLET_ID'])
# end

# def cb_balance
#   rest_api = Coinbase::Pro::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])
#   rest_api.coinbase_accounts.each do |cba|
#     return cba['balance'].to_f if cba['name'] == 'USD Wallet'
#   end
# end

def balLoop(seconds = 0)
  redis = Redis.new
  seconds = balancePortfolioContinual(seconds) while redis.get('balanceLoop') == 'true'
end

def balancePortfolioContinual(seconds = 0)
  rest_api = Coinbase::Pro::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])
  redis = Redis.new

  prompt = TTY::Prompt.new
  seconds = prompt.ask('How many often? (seconds): ', default: 900) if seconds == 0
  og_seconds = seconds

  rest_api = Coinbase::Pro::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])

  # loop do
  orderz = balancePortfolio

  # seconds = seconds.to_i * 3 if orderz.count > 0
  seconds = 15 if orderz.count > 0

  # binding.pry
  # print "\r"
  # sleep seconds.to_i

  t = Time.new(0)
  seconds.to_i.downto(0) do |seconds|
    print (t + seconds).strftime('%H:%M:%S')
    sleep 1
    print "\r"
    k = GetKey.getkey
    system('stty -raw echo')
    case k
    when 120
      cancel_orders orderz
      redis.set('balanceLoop', 'false')
      return og_seconds
    when 97
      unless prompt.no?('Abort?')
        redis.set('BTC_split', 0)
        redis.set('LTC_split', 0)
        redis.set('ETH_split', 0)
        redis.set('BCH_split', 0)
        redis.set('XRP_split', 0)
        redis.set('LINK_split', 0)
        redis.set('balanceLoop', 'true')
        return og_seconds
      end
    end
  end

  cancel_orders orderz
  # balancePortfolioContinual(og_seconds)
  og_seconds
end

def balancePortfolio
  begin
    b = balances
  rescue StandardError => e
    Raven.capture_exception(e)
    sleep 1
    retry
  end
  return [] if orders.count != 0

  orderz = []
  b.each do |balnc|
    next unless balnc['cur'] != 'USD'

    # binding.pry
    orderz << if balnc['BorS']['move'] == 'buy'
                #        puts "buying #{balnc['BorS']['size'].abs} #{balnc['cur']} @ #{balnc['BorS']['price']}"
                buy(balnc['cur'] + '-USD', balnc['BorS']['price'], balnc['BorS']['size'].abs)
              else
                #        puts "selling #{balnc['BorS']['size'].abs} #{balnc['cur']} @ #{balnc['BorS']['price']}"
                sell2(balnc['cur'] + '-USD', balnc['BorS']['price'], balnc['BorS']['size'].abs)
              end
  end
  orderz.compact
end

def balances
  rest_api = Coinbase::Pro::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])
  redis = Redis.new

  # acts = %w[LTC BCH BTC ETH]
  acts = [
    {
      'cur' => 'LTC',
      'split' => redis.get('LTC_split').to_f
    },
    {
      'cur' => 'BCH',
      'split' => redis.get('BCH_split').to_f
    },
    {
      'cur' => 'BTC',
      'split' => redis.get('BTC_split').to_f
    },
    {
      'cur' => 'ETH',
      'split' => redis.get('ETH_split').to_f
    },
    {
      'cur' => 'XRP',
      'split' => redis.get('XRP_split').to_f
    },
    {
      'cur' => 'LINK',
      'split' => redis.get('LINK_split').to_f
    }
  ]
  balncs = []
  total = 0
  acts.each do |act|
    balnc = balanceInUsd(act['cur'])
    balncs << {
      'cur' => act['cur'],
      'bal' => balnc,
      'split' => act['split']
    }
    total += balnc
  end

  balncs << {
    'cur' => 'USD',
    'bal' => bal.round_down(2),
    'split' => 1 - (redis.get('LTC_split').to_f + redis.get('BCH_split').to_f + redis.get('BTC_split').to_f + redis.get('ETH_split').to_f + redis.get('XRP_split').to_f + redis.get('LINK_split').to_f)
  }
  total += bal.round_down(2)
  # binding.pry
  balsWPercents = []
  balncs.each do |balnc|
    balnc['per'] = ((balnc['bal'] / total) * 100).round_down(2)
    # balnc['dif'] = (total / (acts.count + 1)) - balnc['bal']
    balnc['dif'] = (total * balnc['split']) - balnc['bal']
    # binding.pry
    # balnc['dif'] = 0 - balnc['bal']
    if balnc['cur'] != 'USD'
      # binding.pry
      if balnc['cur'] != 'XRP' && balnc['cur'] != 'LINK'
        balnc['BorS'] = if balnc['dif'].positive?
                          {
                            'size' => format('%.8f', (balnc['dif'] / format('%.2f', redis.get("spot_#{balnc['cur']}_USD")).to_f)).to_f,
                            'price' => (redis.get("spot_#{balnc['cur']}_USD").to_f.round_down(2) * 0.998).round_down(2),
                            'move' => 'buy'
                          }
                        else
                          {
                            'size' => format('%.8f', (balnc['dif'] / format('%.2f', redis.get("spot_#{balnc['cur']}_USD")).to_f)).to_f,
                            'price' => (redis.get("spot_#{balnc['cur']}_USD").to_f.round_down(2) * 1.002).round_down(2),
                            'move' => 'sell'
                          }
                        end
      elsif balnc['cur'] == 'XRP'
        balnc['BorS'] = if balnc['dif'].positive?
                          {
                            'size' => format('%.8f', (balnc['dif'] / format('%.2f', redis.get("spot_#{balnc['cur']}_USD")).to_f)).to_f.round_down(0).abs >= redis.get('XRP_min').to_i ? format('%.8f', (balnc['dif'] / format('%.2f', redis.get("spot_#{balnc['cur']}_USD")).to_f)).to_f.round_down(0) : 0,
                            'price' => (redis.get("spot_#{balnc['cur']}_USD").to_f.round_down(4) * 0.998).round_down(4),
                            'move' => 'buy'
                          }
                        else
                          {
                            'size' => format('%.8f', (balnc['dif'] / format('%.2f', redis.get("spot_#{balnc['cur']}_USD")).to_f)).to_f.round_down(0).abs >= redis.get('XRP_min').to_i ? format('%.8f', (balnc['dif'] / format('%.2f', redis.get("spot_#{balnc['cur']}_USD")).to_f)).to_f.round_down(0) : 0,
                            'price' => (redis.get("spot_#{balnc['cur']}_USD").to_f.round_down(4) * 1.002).round_down(4),
                            'move' => 'sell'
                          }
                        end
      elsif balnc['cur'] == 'LINK'
        balnc['BorS'] = if balnc['dif'].positive?
                          {
                            'size' => format('%.2f', (balnc['dif'] / format('%.2f', redis.get("spot_#{balnc['cur']}_USD")).to_f)).to_f,
                            'price' => (redis.get("spot_#{balnc['cur']}_USD").to_f.round_down(5) * 0.998).round_down(5),
                            'move' => 'buy'
                          }
                        else
                          {
                            'size' => format('%.2f', (balnc['dif'] / format('%.2f', redis.get("spot_#{balnc['cur']}_USD")).to_f)).to_f,
                            'price' => (redis.get("spot_#{balnc['cur']}_USD").to_f.round_down(5) * 1.002).round_down(5),
                            'move' => 'sell'
                          }
        end

      end
    end
    balsWPercents << balnc
  end

  balsWPercents
end

def update_accounts
  rest_api = Coinbase::Pro::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])

  accounts = []

  rest_api.accounts do |resp|
    resp.each do |account|
      held = 0
      rest_api.account_holds(account.id) do |resp2|
        resp2.each do |hold|
          held += hold['amount'].to_f
        end
      end
      accounts << Account.new(account.id, account.currency, account.available, held)
      p format("Account balance is %.2f #{account.currency}", account.balance)
    end
  end

  accounts
end

def orders
  rest_api = Coinbase::Pro::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])

  orders = []

  begin
    rest_api.orders(status: 'open') do |resp|
      resp.each do |order|
        orders << order
      end
      # puts "You have #{resp.count} open orders."
    end
  rescue Coinbase::Pro::BadRequestError => e
    if e.message == 'request timestamp expired'
      sleep 1
      retry
    else
      Raven.capture_exception(e)
    end
  rescue StandardError => e # Never rescue Exception *unless* you re-raise in rescue body
    Raven.capture_exception(e)
    sleep 1
    retry
  end

  orders
end

def cancel_orders(orders)
  rest_api = Coinbase::Pro::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])
  sleep 1
  begin
    if orders.count > 0
      orders.each do |order|
        rest_api.cancel(order.id) do
          puts 'Order canceled successfully'
        end
      rescue Coinbase::Pro::NotFoundError => e
        next
      rescue StandardError => e
        Raven.capture_exception(e)
        next
      end
    end
  rescue Exception => e
    Raven.capture_exception(e)
    puts e
  end
end

def parseARGV(switch)
  (0...ARGV.length).each do |i|
    return ARGV[i + 1] if ARGV[i] == switch
  end
end

def processCLI
  unless ARGV.empty?

    case parseARGV '-f'
    when 'balance', 'b'
      redis = Redis.new
      redis.set('balanceLoop', 'true')
      balLoop (parseARGV '-s').to_i
    else
      binding.pry
    end
  end
end
