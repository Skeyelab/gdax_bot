def humanize secs
	[[60, :seconds], [60, :minutes], [24, :hours], [1000, :days]].map{ |count, name|
		if secs > 0
			secs, n = secs.divmod(count)
			"#{n.to_i} #{name}"
		end
	}.compact.reverse.join(' ')
end

class Numeric
	def percent_of(n)
		self.to_f / n.to_f * 100.0
	end
end

class Float
	def round_down n=0
		n < 1 ? self.to_i.to_f : (self - 0.5 / 10**n).round(n)
	end
end



def usd_bal
	rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])

	rest_api.accounts do |resp|
		resp.each do |account|
			if account.currency == "USD"
				return account.available.to_f - 0.01
			end
		end
	end
end

def decimals(a)
	num = 0
	while(a != a.to_i)
		num += 1
		a *= 10
	end
	num
end

class Account
	def initialize(id, currency, balance=0, hold=0)
		@id = id
		@currency = currency
		@balance = balance
		@hold = hold
	end
end


def bal(pair="BTC-USD")
	rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])

	rest_api.accounts do |resp|
		resp.each do |account|
			if account.currency == pair.split('-')[1]
				return account.available.to_f.round_down(8)
			end
		end
	end
end


def update_accounts
	rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])

	accounts = []

	rest_api.accounts do |resp|
		resp.each do |account|
			held = 0
			rest_api.account_holds(account.id) do |resp|
				resp.each do |hold|
					held = held + hold["amount"].to_f
				end
			end
			accounts << Account.new(account.id, account.currency, account.available, held)
		end
	end

	return accounts
end

def orders
	rest_api = Coinbase::Exchange::Client.new(ENV['GDAX_TOKEN'], ENV['GDAX_SECRET'], ENV['GDAX_PW'])

	orders = []

	rest_api.orders(status: "open") do |resp|
		resp.each do |order|
			orders << order
		end
		puts "You have #{resp.count} open orders."
	end

	return orders

end
