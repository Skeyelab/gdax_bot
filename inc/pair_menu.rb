# frozen_string_literal: true

def pair_menu
  prompt = TTY::Prompt.new
  choices = %w[LTC-BTC ETH-BTC BCH-BTC BTC-USD ETH-USD LTC-USD BCH-USD ETC-BTC ZRX-BTC XRP-USD Back]
  prompt.enum_select('Pair?', choices, per_page: 10)
end
