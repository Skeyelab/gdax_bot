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

  redis.set('BTC_split', 0.2) unless redis.get('BTC_split')
  redis.set('LTC_split', 0.2) unless redis.get('LTC_split')
  redis.set('ETH_split', 0.2) unless redis.get('ETH_split')
  redis.set('BCH_split', 0.2) unless redis.get('BCH_split')
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
  rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])

  rest_api.accounts do |resp|
    resp.each do |account|
      return account.available.to_f - 0.01 if account.currency == 'USD'
    end
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

# Account class
class Account
  def initialize(id, currency, balance = 0, hold = 0)
    @id = id
    @currency = currency
    @balance = balance
    @hold = hold
  end
end

def bal(pair = 'BTC-USD')
  rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])

  rest_api.accounts do |resp|
    resp.each do |account|
      return account.available.to_f.round_down(8) if account.currency == pair.split('-')[1]
    end
  end
end

def balanceInUsd(currency)
  rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])
  redis = Redis.new

  rest_api.accounts do |resp|
    resp.each do |account|
      # binding.pry
      spot = format('%.5f', redis.get("spot_#{currency}_USD")).to_f
      begin
        return((account.available.to_f.round_down(8) + account.hold.to_f.round_down(8)) * spot).round_down(2) if account.currency == currency
      rescue Exception => e
        puts e
        return 0
      end
    end
  end
end

def balancePortfolioContinual(seconds = 0)
  redis = Redis.new

  rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])

  prompt = TTY::Prompt.new
  if seconds == 0
    seconds = prompt.ask('How many often? (seconds): ', default: 900)
  end
  rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])

  # loop do
  orders = balancePortfolio

  # binding.pry
  #print "\r"
  #sleep seconds.to_i

  t = Time.new(0)
  seconds.to_i.downto(0) do |seconds|
    print (t + seconds).strftime('%H:%M:%S')
    sleep 1
    print "\r"
    k = GetKey.getkey
    system('stty -raw echo')
    case k
    when 120
      cancel_orders orders
      return
    when 97
      if !prompt.no?('Abort?')
        redis.set('BTC_split', 0)
        redis.set('LTC_split', 0)
        redis.set('ETH_split', 0)
        redis.set('BCH_split', 0)
        break
      end
    end
  end

  cancel_orders orders
  balancePortfolioContinual(seconds)

end

def balancePortfolio
  b = balances
  return [] if orders.count != 0

  orderz = []
  b.each do |balnc|
    if balnc['cur'] != 'USD'
      # binding.pry
      if balnc['BorS']['move'] == 'buy'
        puts "buying #{balnc['BorS']['size'].abs} #{balnc['cur']} @ #{balnc['BorS']['price']}"
        orderz << buy(balnc['cur'] + '-USD', balnc['BorS']['price'], balnc['BorS']['size'].abs)
      else
        puts "selling #{balnc['BorS']['size'].abs} #{balnc['cur']} @ #{balnc['BorS']['price']}"
        orderz << sell2(balnc['cur'] + '-USD', balnc['BorS']['price'], balnc['BorS']['size'].abs)
      end
    end
  end
  orderz.compact
end

def balances
  rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])
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
    'split' => 1 - (redis.get('LTC_split').to_f + redis.get('BCH_split').to_f + redis.get('BTC_split').to_f + redis.get('ETH_split').to_f)
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
      balnc['BorS'] = if balnc['dif'].positive?
                        {
                          'size' => format('%.8f', (balnc['dif'] / format('%.2f', redis.get("spot_#{balnc['cur']}_USD")).to_f)).to_f,
                          'price' => (redis.get("spot_#{balnc['cur']}_USD").to_f.round_down(2) * 0.9995).round_down(2),
                          'move' => 'buy'
                        }
                      else
                        {
                          'size' => format('%.8f', (balnc['dif'] / format('%.2f', redis.get("spot_#{balnc['cur']}_USD")).to_f)).to_f,
                          'price' => (redis.get("spot_#{balnc['cur']}_USD").to_f.round_down(2) * 1.0005).round_down(2),
                          'move' => 'sell'
                        }
                      end
    end
    balsWPercents << balnc
  end

  balsWPercents
end

def update_accounts
  rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])

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
  rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])

  orders = []

  rest_api.orders(status: 'open') do |resp|
    resp.each do |order|
      orders << order
    end
    puts "You have #{resp.count} open orders."
  end

  orders
end


def cancel_orders orders
  rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])
  sleep 1
  begin
    if orders.count > 0
      orders.each do |order|
        rest_api.cancel(order.id) do
          puts 'Order canceled successfully'
        end
      rescue StandardError => e
        puts e
        # binding.pry
        next
      end
    end
  rescue Exception => e
    puts e
  end
end
