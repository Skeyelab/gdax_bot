# frozen_string_literal: true

require 'rubygems'
require 'bundler'
Bundler.require
Dotenv.load
system('clear')
Dir['./inc/*.rb'].each { |file| require file }
# redis = Redis.new

loop do
  k = GetKey.getkey
  puts "Key pressed: #{k.inspect}"
  sleep 1
end
