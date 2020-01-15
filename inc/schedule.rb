# frozen_string_literal: true

scheduler = Rufus::Scheduler.new

scheduler.every '10m' do
  takeProfitTo redis.get('ProfitTo').to_f
end
