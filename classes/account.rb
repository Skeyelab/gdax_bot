# Account class
class Account
    def initialize(id, currency, balance = 0, hold = 0)
      @id = id
      @currency = currency
      @balance = balance
      @hold = hold
    end
end