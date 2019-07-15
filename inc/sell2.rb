# frozen_string_literal: true

def sell2(pair, price, order_size)
  rest_api = Coinbase::Pro::Client.new(
    ENV['GDAX_TOKEN'],
    ENV['GDAX_SECRET'],
    ENV['GDAX_PW'],
    product_id: pair
  )

  begin
    sell_order = rest_api.sell(order_size, price)
    puts 'selling'.red + " #{order_size.abs} #{pair.chomp('-USD')} @ #{price} - #{Time.now} | #{Time.now.getgm}"
    return sell_order
  rescue Coinbase::Pro::NotFoundError => e
    if e.message == '{"message":"NotFound"}'
      puts 'Order not found'
      sleep 1
      return sell_order
    end
  rescue StandardError => e
    # puts e
  end
  # binding.pry
end
