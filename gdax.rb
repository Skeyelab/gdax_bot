# frozen_string_literal: true

require 'rubygems'
require 'bundler'
Bundler.require

Dotenv.load
system('clear')
Dir['./inc/*.rb'].sort.each { |file| require file }
require 'zeitwerk'
$loader = Zeitwerk::Loader.new
$loader.push_dir('classes')
$loader.setup # ready!

init_env
init_redis
check_for_zombie_servers

Rollbar.configure do |config|
  config.access_token = ENV['ROLLBAR_KEY']
  config.logger_level = 'warn'
end

web_socket_daemon = Daemons.call(app_name: 'GDAX_Bot', backtrace: true, multiple: true) do
  run_websocket
end
rest_api = Coinbase::Pro::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])

# web_server_daemon = Daemons.call({ :app_name => 'Webserver', :monitor => true, :backtrace => true, :multiple => true}) do
#   startWebserver
# end

begin
  processCLI
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
  system('rm .rufus-scheduler.lock')
end
