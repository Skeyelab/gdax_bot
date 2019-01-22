# frozen_string_literal: true

require 'rubygems'
require 'bundler'
Bundler.require
Dotenv.load
system('clear')
Dir['./inc/*.rb'].each { |file| require file }
require 'zeitwerk'
$loader = Zeitwerk::Loader.new
$loader.push_dir('classes')
$loader.setup # ready!

init_env
init_redis
check_for_zombie_servers

web_socket_daemon = Daemons.call(app_name: 'GDAX_Bot', backtrace: true, multiple: true) do
  run_websocket
end

# web_server_daemon = Daemons.call({ :app_name => 'Webserver', :monitor => true, :backtrace => true, :multiple => true}) do
#   startWebserver
# end

begin
  Menus.main_menu
rescue SystemExit => e
  puts "Error: #{e}"
  abort
rescue StandardError => e
  puts "Error: #{e}"
  Menus.main_menu
ensure
  web_socket_daemon.stop
  #  web_server_daemon.stop
  system('stty -raw echo')
end
