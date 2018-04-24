# frozen_string_literal: true

require 'rubygems'
require 'bundler'
Bundler.require
Dotenv.load
system('clear')
Dir['./inc/*.rb'].each {|file| require file }

init_env
init_redis
check_for_zombie_servers

webSocket_daemon = Daemons.call({ app_name: 'GDAX_Bot',backtrace: true, multiple: true}) do
  run_websocket
end

webServer_daemon = Daemons.call({ app_name: 'Webserver',backtrace: true, multiple: true}) do
  startWebserver
end

begin

  gdax_bot_main_menu
rescue SystemExit => e
  abort
rescue Exception => e
  puts "Error: #{e}"
  gdax_bot_main_menu
  ensure
    webSocket_daemon.stop
    webServer_daemon.stop
    system('stty -raw echo')
end
