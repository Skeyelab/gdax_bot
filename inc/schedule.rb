# frozen_string_literal: true

begin
  scheduler = Rufus::Scheduler.new(lockfile: '.rufus-scheduler.lock')
  redis = Redis.new

  # scheduler.every '30m' do
  #   $loader.reload
  # end

#  scheduler.cron '*/3 * * * *' do
scheduler.every '10s' do
    if redis.get('takeProfits') == 'true'
      begin
        takeProfitTo redis.get('ProfitTo').to_f
      rescue StandardError => e
        Raven.capture_exception(e)
        raise e
      end
    end
  end
rescue Rufus::Scheduler::NotRunningError => e
  puts 'scheduler already running'
end
