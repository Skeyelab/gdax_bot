# frozen_string_literal: true

begin
  scheduler = Rufus::Scheduler.new(lockfile: '.rufus-scheduler.lock')
  redis = Redis.new

  scheduler.cron '*/3 * * * *' do
    if redis.get('takeProfits') == 'true'
      takeProfitTo redis.get('ProfitTo').to_f
    end
  end
rescue Rufus::Scheduler::NotRunningError => e
  puts 'scheduler already running'
end
