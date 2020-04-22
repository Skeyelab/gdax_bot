# frozen_string_literal: true

# CB class
class Cb
  def self.balance
    rest_api = Coinbase::Pro::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])
    begin
      rest_api.coinbase_accounts.each do |cba|
        return cba['balance'].to_f if cba['name'] == 'USD Wallet'
      end
    rescue Coinbase::Pro::RateLimitError
      sleep 1
      retry
    end
  end

  def self.withdraw(dollars)
    rest_api = Coinbase::Pro::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])
    begin
      rest_api.coinbase_withdrawal(dollars, 'USD', ENV['CB_WALLET_ID'])
    rescue Coinbase::Pro::RateLimitError
      sleep 1
      retry
    end
  end

  def self.deposit(dollars)
    rest_api = Coinbase::Pro::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])
    begin
      rest_api.coinbase_deposit(dollars, 'USD', ENV['CB_WALLET_ID'])
    rescue Coinbase::Pro::RateLimitError
      sleep 1
      retry
    end
  end
end
