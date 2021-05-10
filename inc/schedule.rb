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
        if (totalBalanceInUsd < (redis.get('ProfitTo').to_f * redis.get('stopPercent').to_f)) && balancePortfolio.count.zero?
          try_push_message("Go check the GDAX Bot","AUTO SELL", "intermission")
          binding.pry
          redis.set('orderSizeDividedBy', 1)
          redis.set('spread', 0.000)
          redis.set('BTC_split', 0)
          redis.set('LTC_split', 0)
          redis.set('ETH_split', 0)
          redis.set('BCH_split', 0)
          # redis.set('XRP_split', 0)
          redis.set('LINK_split', 0)
          redis.set('balanceLoop', 'true')
        end
      rescue StandardError => e
        Raven.capture_exception(e)
        raise e
      end
    end
  end
rescue Rufus::Scheduler::NotRunningError => e
  puts 'scheduler already running'
end
