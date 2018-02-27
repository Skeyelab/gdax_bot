require 'rubygems'
require 'bundler'
Bundler.require
Dotenv.load
system('clear')
Dir["./inc/*.rb"].each {|file| require file }


# rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])

# rest_api.accounts do |resp|
#   resp.each do |account|
#     p "#{account.id}: %.8f #{account.currency} available for trading" % account.available
#   end
# end

def pair_menu
	prompt = TTY::Prompt.new
	choices = %w(LTC-BTC ETH-BTC BCH-BTC BTC-USD ETH-USD LTC-USD BCH-USD Back)
	return prompt.enum_select("Pair?", choices, per_page: 8)
end

def gdax_bot
	redis = Redis.new

	loop do

		prompt = TTY::Prompt.new
		choice = prompt.select("Choose your destiny?") do |menu|
			menu.enum '.'

			#menu.choice 'Open and Close Order', 'open_and_close'
			menu.choice 'Trailing Stop', 'trailing_stop'
			menu.choice 'View Data Stream', 'view_websocket'
			menu.choice 'Prompt', 'prompt'
			menu.choice 'Exit', 'exit'
		end

		case choice
		when 'exit'
			abort
		when 'prompt'
			binding.pry
		when 'view_websocket'
			view_websocket
		when 'trailing_stop'
			trailing_start_menu
		end
	end

end

check_for_zombie_websocket

ws_task = Daemons.call({ :app_name => "GDAX_Connection",:backtrace  => true}) do
	run_websocket
end

begin
	gdax_bot
rescue SystemExit => e
	abort
rescue Exception => e
	puts "Error: #{e}"
	gdax_bot
ensure
	ws_task.stop
	system('stty -raw echo')
end
