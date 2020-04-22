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
    sell_order
  rescue Coinbase::Pro::NotFoundError => e
    Raven.capture_exception(e)
    if e.message == '{"message":"NotFound"}'
      puts 'Order not found'
      sleep 1
      sell_order
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
  # binding.pry
end
