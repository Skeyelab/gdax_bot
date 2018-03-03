require 'rubygems'
require 'bundler'
Bundler.require
Dotenv.load
system('clear')
Dir["./inc/*.rb"].each {|file| require file }

init_env
init_redis
check_for_zombie_websocket

ws_task = Daemons.call({ :app_name => "GDAX_Connection",:backtrace  => true}) do
	run_websocket
end

begin
	gdax_bot_main_menu
rescue SystemExit => e
	abort
rescue Exception => e
	puts "Error: #{e}"
	gdax_bot_main_menu
	ensure
	ws_task.stop
	system('stty -raw echo')
end
