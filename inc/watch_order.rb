# frozen_string_literal: true

def watch_order(order)
  redis = Redis.new

  pair = order.product_id

  rest_api = Coinbase::Pro::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'], product_id: pair)
  puts "Press 'c' to cancel the order"
  system('stty raw -echo')
  spinner = TTY::Spinner.new(
    "[:spinner] #{order.side.capitalize}ing :size :p1 for :price :p2 - Current spread: :spread", format: :bouncing_ball, hide_cursor: true
  )
  loop do
    spot = format('%.5f', redis.get("spot_#{pair.split('-')[0]}_#{pair.split('-')[1]}"))
    spinner.update(p1: pair.split('-')[0])
    spinner.update(p2: pair.split('-')[1])
    spinner.update(size: format('%.8f', order.size))
    spinner.update(price: format('%.5f', order.price))
    spinner.update(spread: format('%.5f', (spot.to_f - order.price)))
    spinner.spin
    rest_api = Coinbase::Pro::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'], product_id: pair)

    k = GetKey.getkey

    case k
    when 99
      system('stty -raw echo')
      spinner.error('Cancelling order')
      rest_api.cancel(order.id) do
        puts 'Order canceled successfully'
        return false
      end
    when 120
      system('stty -raw echo')
      spinner.error('Exiting')
      break
    end

    if rest_api.order(order.id)['settled']
      system('stty -raw echo')
      spinner.success('(successful)')
      return true
    else
      sleep 1.0 / 3.0
      spinner.spin
    end
  rescue Coinbase::Pro::NotFoundError => e
    Raven.capture_exception(e)
    if e.message == '{"message":"NotFound"}'
      system('stty -raw echo')
      spinner.error('Order not found')
      sleep 1
      return false
    end
  rescue StandardError => e
    Raven.capture_exception(e)
    # puts "Error, retrying"
    # puts e
    sleep 1
    retry
  end
end
