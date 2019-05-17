# frozen_string_literal: true

def buy(pair, price, order_size)
  rest_api = Coinbase::Exchange::Client.new(
    ENV['GDAX_TOKEN'],
    ENV['GDAX_SECRET'],
    ENV['GDAX_PW'],
    product_id: pair
  )

  puts "buying #{order_size.abs} #{pair.chomp('-USD')} @ #{price}"
  begin
    buy_order = rest_api.buy(order_size, price)
    return buy_order
  rescue Coinbase::Exchange::NotFoundError => e
    if e.message == '{"message":"NotFound"}'
      puts 'Order not found'
      sleep 1
      return buy_order
    end
  rescue StandardError => e
    #puts e
  end
  # binding.pry
end
