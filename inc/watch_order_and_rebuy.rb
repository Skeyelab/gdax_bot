# frozen_string_literal: true

def watch_order_and_rebuy(order, rebuy_level)
  rest_api = Coinbase::Exchange::Client.new(ENV["GDAX_TOKEN"], ENV["GDAX_SECRET"], ENV["GDAX_PW"])

  watch_order(order)

  order_size = ((bal(order.product_id) * 0.99) / rebuy_level).round_down(5)

  puts "Rebuying #{order_size} BTC @ $#{rebuy_level}"
  open_order = rest_api.buy(order_size, rebuy_level)
  open_order
end
