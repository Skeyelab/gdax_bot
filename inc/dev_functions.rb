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
			#system('stty -raw echo') # => Reset terminal mode
			return char
		else
			return Win32API.new('crtdll', '_kbhit', [ ], 'I').Call.zero? ? nil : Win32API.new('crtdll', '_getch', [ ], 'L').Call
		end
	end

end

def watch_stream_times
	redis = Redis.new

	loop do
		puts redis.get("last_ws_message_time")
		sleep 1
	end
end

def check_for_zombie_websocket

	begin
		file = File.open("./GDAX_Connection.pid", "rb")
		contents = file.read
		pid = contents.to_i
		Process.kill("QUIT", pid)
		return
	rescue Exception => e
		return
	end

end
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
		puts "$%.2f" % redis.get("spot_BTC_USD") + " | " + "$%.2f" % redis.get("spot_ETH_USD") + " | " + "$%.2f" % redis.get("spot_LTC_USD") + " | " + "Ƀ%.5f" % redis.get("spot_ETH_BTC") + " | " + "Ƀ%.5f" % redis.get("spot_LTC_BTC") + " | " + "$%.2f" % redis.get("spot_BCH_USD") + " | " + "Ƀ%.5f" % redis.get("spot_BCH_BTC")
		sleep 1.0/20
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

	websocket = Coinbase::Exchange::Websocket.new( keepalive: true)
	websocket.match do |resp|
		redis.set("last_ws_message_time", resp["time"])

		case resp.product_id
		when "BTC-USD"
			redis.set("spot_BTC_USD", resp.price)
			#p "BTC Spot Rate: $ %.2f" % resp.price
		when "ETH-USD"
			redis.set("spot_ETH_USD", resp.price)
			#p "ETH Spot Rate: $ %.2f" % resp.price
		when "LTC-USD"
			redis.set("spot_LTC_USD", resp.price)
			#p "LTC Spot Rate: $ %.2f" % resp.price
		when "ETH-BTC"
			redis.set("spot_ETH_BTC", resp.price)
			#p "LTC Spot Rate: $ %.2f" % resp.price
		when "LTC-BTC"
			redis.set("spot_LTC_BTC", resp.price)
			#p "LTC Spot Rate: $ %.2f" % resp.price
		when "BCH-USD"
			redis.set("spot_BCH_USD", resp.price)
			#p "LTC Spot Rate: $ %.2f" % resp.price
		when "BCH-BTC"
			redis.set("spot_BCH_BTC", resp.price)
			#p "LTC Spot Rate: $ %.2f" % resp.price
		end
		#puts "."
		#puts "$%.2f" % redis.get("spot_BTC_USD") + " | " + "$%.2f" % redis.get("spot_ETH_USD") + " | " + "$%.2f" % redis.get("spot_LTC_USD") + " | " + "Ƀ%.5f" % redis.get("spot_ETH_BTC") + " | " + "Ƀ%.5f" % redis.get("spot_LTC_BTC") + " | " + "$%.2f" % redis.get("spot_BCH_USD") + " | " + "Ƀ%.5f" % redis.get("spot_BCH_BTC")

	end

	EM.run do
		websocket.start!
		EM.add_periodic_timer(1) {
			if (Time.now - Time.parse(redis.get("last_ws_message_time"))) > 5
				websocket.start!
			end
		}
		EM.error_handler { |e|
			sleep 1
		}
	end

	#websocket.start!

end
