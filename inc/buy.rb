# frozen_string_literal: true

def buy(pair, price, order_size)
  rest_api = Coinbase::Pro::Client.new(
    ENV['GDAX_TOKEN'],
    ENV['GDAX_SECRET'],
    ENV['GDAX_PW'],
    product_id: pair
  )

  begin
    buy_order = rest_api.buy(order_size, price)
    puts "buying".green + " #{order_size.abs} #{pair.chomp('-USD')} @ #{price} - #{Time.now} | #{Time.now.getgm}"
    return buy_order
  rescue Coinbase::Pro::NotFoundError => e
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
