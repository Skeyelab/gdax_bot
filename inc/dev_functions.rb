# frozen_string_literal: true

# GetKey Module
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
      (begin
        $stdin.read_nonblock(1).ord
       rescue StandardError
         nil
      end)
      # system('stty -raw echo') # => Reset terminal mode

    else
      Win32API.new('crtdll', '_kbhit', [], 'I').Call.zero? ? nil : Win32API.new('crtdll', '_getch', [], 'L').Call
    end
  end
end

def watch_stream_times
  redis = Redis.new

  loop do
    puts redis.get('last_ws_message_time')
    sleep 1
  end
end

def write_json
  Thread.new do
    # redis = Redis.new
    loop do
      File.open('./public/blah.json', 'w') { |file| file.write(Time.now) }
      # or call tick function
      sleep 1
    end
  end
end

def check_for_zombie_servers
  Dir.glob('./*.pid') do |file|
    file = File.open(file, 'rb')
    contents = file.read
    pid = contents.to_i
    Process.kill('QUIT', pid)
    break
  rescue StandardError
    break
  end
end

# Process Module
module Process
  def exist?(pid)
    Process.kill(0, pid)
    true
  rescue Errno::ESRCH
    false
  end

  module_function :exist?
end

def view_websocket
  redis = Redis.new

  loop do
    puts format('$%.2f',
                redis.get('spot_BTC_USD')) + ' | ' + format('$%.2f',
                                                            redis.get('spot_ETH_USD')) + ' | ' + format('$%.2f',
                                                                                                        redis.get('spot_LTC_USD')) + ' | ' + format('Ƀ%.5f',
                                                                                                                                                    redis.get('spot_ETH_BTC')) + ' | ' + format('Ƀ%.5f',
                                                                                                                                                                                                redis.get('spot_LTC_BTC')) + ' | ' + format('$%.2f',
                                                                                                                                                                                                                                            redis.get('spot_BCH_USD')) + ' | ' + format('Ƀ%.5f',
                                                                                                                                                                                                                                                                                        redis.get('spot_BCH_BTC')) + ' | ' + format('Ƀ%.5f',
                                                                                                                                                                                                                                                                                                                                    redis.get('spot_ETC_BTC')) + ' | ' + format('Ƀ%.8f',
                                                                                                                                                                                                                                                                                                                                                                                redis.get('spot_ZRX_BTC')) + ' | ' + format(
                                                                                                                                                                                                                                                                                                                                                                                  '$%.5f', redis.get('spot_LINK_USD')
                                                                                                                                                                                                                                                                                                                                                                                )
    sleep 1.0 / 20
    k = GetKey.getkey
    system('stty -raw echo')
    case k
    when 120
      break
    end
  end
end

def run_websocket
  redis = Redis.new

  websocket = Coinbase::Pro::Websocket.new(keepalive: true)
  websocket.match do |resp|
    redis.set('last_ws_message_time', resp['time'])

    case resp.product_id
    when 'BTC-USD'
      redis.set('spot_BTC_USD', resp.price)
    # p "BTC Spot Rate: $ %.2f" % resp.price
    when 'ETH-USD'
      redis.set('spot_ETH_USD', resp.price)
    # p "ETH Spot Rate: $ %.2f" % resp.price
    when 'LTC-USD'
      redis.set('spot_LTC_USD', resp.price)
    # p "LTC Spot Rate: $ %.2f" % resp.price
    when 'ETH-BTC'
      redis.set('spot_ETH_BTC', resp.price)
    # p "LTC Spot Rate: $ %.2f" % resp.price
    when 'LTC-BTC'
      redis.set('spot_LTC_BTC', resp.price)
    # p "LTC Spot Rate: $ %.2f" % resp.price
    when 'BCH-USD'
      redis.set('spot_BCH_USD', resp.price)
    # p "LTC Spot Rate: $ %.2f" % resp.price
    # when 'XRP-USD'
    #   redis.set('spot_XRP_USD', resp.price)
    # p "LTC Spot Rate: $ %.2f" % resp.price
    when 'BCH-BTC'
      redis.set('spot_BCH_BTC', resp.price)
      # p "LTC Spot Rate: $ %.2f" % resp.price
    when 'ETC-BTC'
      redis.set('spot_ETC_BTC', resp.price)
      # p "LTC Spot Rate: $ %.2f" % resp.price
    when 'ZRX-BTC'
      redis.set('spot_ZRX_BTC', resp.price)
      # p "LTC Spot Rate: $ %.2f" % resp.price
    when 'LINK-USD'
      redis.set('spot_LINK_USD', resp.price)
      # p "LTC Spot Rate: $ %.2f" % resp.price
    end
    sleep 1.0 / 1000
    # puts "."
    # puts "$%.2f" % redis.get("spot_BTC_USD") + " | " + "$%.2f" % redis.get("spot_ETH_USD") + " | " + "$%.2f" % redis.get("spot_LTC_USD") + " | " + "Ƀ%.5f" % redis.get("spot_ETH_BTC") + " | " + "Ƀ%.5f" % redis.get("spot_LTC_BTC") + " | " + "$%.2f" % redis.get("spot_BCH_USD") + " | " + "Ƀ%.5f" % redis.get("spot_BCH_BTC")
  end

  EM.run do
    websocket.start!
    EM.add_periodic_timer(30) do
      if (Time.now - Time.parse(redis.get('last_ws_message_time'))) > 30
        websocket.start!
      end
    end
    EM.error_handler do |_e|
      sleep 1
    end
  end
  # websocket.start!
end
