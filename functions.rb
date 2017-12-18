module GetKey

  # Check if Win32API is accessible or not
  @use_stty = begin
    require 'Win32API'
    false
  rescue LoadError
    # Use Unix way
    true
  end

  # Return the ASCII code last key pressed, or nil if none
  #
  # Return::
  # * _Integer_: ASCII code of the last key pressed, or nil if none
  def self.getkey
    if @use_stty
      system('stty raw -echo') # => Raw mode, no echo
      char = (STDIN.read_nonblock(1).ord rescue nil)
      system('stty -raw echo') # => Reset terminal mode
      return char
    else
      return Win32API.new('crtdll', '_kbhit', [ ], 'I').Call.zero? ? nil : Win32API.new('crtdll', '_getch', [ ], 'L').Call
    end
  end

end

class Numeric
  def percent_of(n)
    self.to_f / n.to_f * 100.0
  end
end

class Float
  def round_down n=0
    n < 1 ? self.to_i.to_f : (self - 0.5 / 10**n).round(n)
  end
end

class Account
  def initialize(id, currency, balance=0, hold=0)
    @id = id
    @currency = currency
    @balance = balance
    @hold = hold
  end
end

def usd_bal
  rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])

  rest_api.accounts do |resp|
    resp.each do |account|
      if account.currency == "USD"
        return account.available.to_f - 0.01
      end
    end
  end
end

def decimals(a)
  num = 0
  while(a != a.to_i)
    num += 1
    a *= 10
  end
  num
end

def onebal(curr="BTC")
  rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])

  rest_api.accounts do |resp|
    resp.each do |account|
      if account.currency == curr
        return account.available.to_f.round_down(8)
      end
    end
  end
end

def bal(pair="BTC-USD")
  rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])

  rest_api.accounts do |resp|
    resp.each do |account|
      if account.currency == pair.split('-')[1]
        return account.available.to_f.round_down(8)
      end
    end
  end
end

def watch_order_and_rebuy (order, rebuy_level)
  rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])

  watch_order(order)


  order_size = ((bal(order.product_id) * 0.99)/rebuy_level).round_down(5)

  puts "Rebuying #{order_size} BTC @ $#{rebuy_level}"
  open_order = rest_api.buy(order_size, rebuy_level)

  end


def spread
  rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])
  rest_api.orderbook do |resp|
    return (resp["asks"][0][0].to_f - resp["bids"][0][0].to_f).round_down(2)
  end
end

def market_skim(times=2, pair="ETH-BTC", percent_of_portfolio=0.99, down=0.00002, up=0.00002)


  redis = Redis.new
  rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'], product_id: pair )
  # while true
  times.times do

    spot = "%.5f" % redis.get("spot_#{pair.split('-')[0]}_#{pair.split('-')[1]}")
    puts "Spot: #{spot}"
    begin
      open_position((spot.to_f - down).round_down(5), (spot.to_f + up).round_down(5), percent_of_portfolio, pair)

    rescue => exception
      puts exception
      break
    end
    sleep 1
  end

end



#def retrace(pair="BTC-USD", sell, rebuy)
def retrace(pair="BTC-USD")
  redis = Redis.new
  rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'], product_id: pair )
  spot = "%.2f" % redis.get("spot_#{pair.split('-')[0]}_#{pair.split('-')[1]}")

  open_rate = 99.percent_of(spot.to_f)

  binding.pry


  #sell_order = rest_api.sell(order_size.round_down(8),open_price)

end


def open_position (open_price, close_price, percent_of_portfolio, pair="BTC-USD" )


  rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'], product_id: pair )


  #binding.pry
  order_size = (bal(pair) * percent_of_portfolio)/open_price

                open_order = rest_api.buy(order_size.round_down(8),open_price)

                close_position(open_order, close_price)
                sleep 1
                end


                def watch_order(order)
                  redis = Redis.new

                  pair = order.product_id

                  rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'], product_id: pair )

                  puts "Checking on order #{order.id}"
                  puts order
                  loop do
                    begin
                      spot = "%.5f" % redis.get("spot_#{pair.split('-')[0]}_#{pair.split('-')[1]}")

                      puts "%.5f" % (spot.to_f - order.price)

                      rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'], product_id: pair )
                      if rest_api.order(order.id)["settled"]
                        return true
                      else
                        sleep 1.0/3.0

                      end

                    rescue Coinbase::Exchange::NotFoundError => e
                      if e.message == "{\"message\":\"NotFound\"}"
                        puts "Order not found"
                        sleep 1
                        return false
                      end
                    rescue Exception => e
                      puts "Error, retrying"
                      puts e
                      sleep 1
                      retry
                    end
                  end
                end




                def close_position (order, price)
                  rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'], product_id: order.product_id )

                  if !watch_order(order)
                    return
                  end
                  order_size = order.size


                  puts ""


                  if order["side"] == "buy"
                    puts "Selling #{order_size.to_f} #{order['product_id'].split('-')[0]} @ $#{price}"

                    begin
                      sell_order = rest_api.sell(order_size,price)
                      puts "Sell order ID is #{sell_order.id}"
                      puts sell_order
                      watch_order sell_order
                      return

                    rescue Coinbase::Exchange::NotFoundError => e
                      if e.message == "{\"message\":\"NotFound\"}"
                        puts "Order not found"
                        sleep 1
                        return
                      end

                    rescue Exception => e
                      binding.pry
                    end


                    # elsif order["side"] == "sell"
                    #   puts "Selling #{order_size} #{order_size} #{order['product_id'].split('-')[0]} @ $#{price}"
                    #   begin
                    #     sell_order = rest_api.buy(order_size,price) do |resp|
                    #       puts "Sell order ID is #{resp.id}"

                    #       return sell_order
                    #     end
                    #   rescue Exception => e
                    #     binding.pry
                    #   end


                  end

                end

                def watch_order_and_sell (order, sell_level)
                  rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])

                  puts "Checking on order #{order.id}"
                  loop do
                    begin
                      rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])
                      if rest_api.order(order.id)["settled"]
                        break
                      else
                        sleep 1.0/3.0
                        print "."
                      end
                    rescue Exception => e
                      puts "Error, retrying"
                      sleep 1
                      retry
                    end
                  end
                  puts ""
                  proceeds = (order["price"].to_f * order["size"].to_f).round_down(2)
                  order_size = (proceeds/sell_level).round_down(8)

                  order_size = (bal(pair) * percent_of_portfolio)/open_price

  puts "Selling #{order_size} BTC @ $#{sell_level}"

  rest_api.sell(order_size,sell_level) do |resp|
    puts "Order ID is #{resp.id}"
  end

end

def update_accounts
  rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])

  accounts = []

  rest_api.accounts do |resp|
    resp.each do |account|
      held = 0
      rest_api.account_holds(account.id) do |resp|
        resp.each do |hold|
          held = held + hold["amount"].to_f
        end
      end
      accounts << Account.new(account.id, account.currency, account.available, held)
    end
  end

  return accounts
end

def update_orders
  rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])

  orders = []

  rest_api.orders(status: "open") do |resp|
    resp.each do |order|
      orders << order
    end
    puts "You have #{resp.count} open orders."
  end

  return orders

end
