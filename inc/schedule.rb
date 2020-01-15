# frozen_string_literal: true

scheduler = Rufus::Scheduler.new
redis = Redis.new

scheduler.every '10m' do
    #puts "Taking profit to #{redis.get('ProfitTo')}"
    takeProfitTo redis.get('ProfitTo').to_f
end
