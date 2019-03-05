# frozen_string_literal: true

def blah_method
  puts "blah"
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
  redis.set('spot_ZRX_BTC', 0) unless redis.get('spot_ZRX_BTC')
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
      #binding.pry
      spot = format('%.5f', redis.get("spot_#{currency}_USD")).to_f
      return((account.available.to_f.round_down(8) + account.hold.to_f.round_down(8)) * spot).round_down(2) if account.currency == currency
    end
  end
end


def balancePortfolioContinual
  while true
    balancePortfolio;
    sleep 900
    k = GetKey.getkey
    system('stty -raw echo')
    case k
    when 120
      break
    end
  end
end


def balancePortfolio
  b = balances;
  b.each do |balnc|
    if balnc["cur"] != "USD"
      #binding.pry
      if balnc["BorS"]["move"] == "buy"
        puts "buying #{balnc['BorS']['size'].abs} #{balnc['cur']} @ #{balnc['BorS']['price']}"
        buy(balnc['cur']+'-USD',balnc['BorS']['price'],balnc['BorS']['size'].abs)
      else
        puts "selling #{balnc['BorS']['size'].abs} #{balnc['cur']} @ #{balnc['BorS']['price']}"
        sell2(balnc['cur']+'-USD',balnc['BorS']['price'],balnc['BorS']['size'].abs)
      end
    end
  end
end



def balances
  rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])
  redis = Redis.new

  acts = ["LTC", "BCH", "BTC", "ETH"]
  balncs = []
  total = 0
  acts.each do |act|
    balnc = balanceInUsd(act)
    balncs << {
      "cur" => act,
      "bal" => balnc
    }
    total = total + balnc
  end
  balncs << {
    "cur" => "USD",
    "bal" => bal.round_down(2)
  }
  total = total + bal.round_down(2)
  #binding.pry
  balsWPercents = []
  balncs.each do |balnc|
    balnc["per"] = ((balnc["bal"]/total)*100).round_down(2)
    balnc["dif"] = (total/5)-balnc["bal"]
    if balnc['cur'] != "USD"
      #binding.pry
      if balnc["dif"].positive?
        balnc["BorS"] = {
          "size" => format('%.5f',(balnc["dif"]/format('%.2f', redis.get("spot_#{balnc['cur']}_USD")).to_f)).to_f,
          "price" => ((redis.get("spot_#{balnc['cur']}_USD").to_f).round_down(2) - 0.02).round_down(2),
          "move" => "buy"
        }
      else
        balnc["BorS"] = {
          "size" => format('%.5f',(balnc["dif"]/format('%.2f', redis.get("spot_#{balnc['cur']}_USD")).to_f)).to_f,
          "price" => ((redis.get("spot_#{balnc['cur']}_USD").to_f).round_down(2) + 0.02).round_down(2),
          "move" => "sell"
        }
      end
    end
    balsWPercents << balnc

  end
   
  return balsWPercents
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
