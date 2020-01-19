# frozen_string_literal: true

begin
  scheduler = Rufus::Scheduler.new(lockfile: '.rufus-scheduler.lock')
  redis = Redis.new

  scheduler.every '10m' do
    takeProfitTo redis.get('ProfitTo').to_f if redis.get('takeProfits') == 'true'
  end
rescue Rufus::Scheduler::NotRunningError => e
  puts "scheduler already running"
end
