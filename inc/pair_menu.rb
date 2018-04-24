def pair_menu
	 prompt = TTY::Prompt.new
	 choices = %w(LTC-BTC ETH-BTC BCH-BTC BTC-USD ETH-USD LTC-USD BCH-USD Back)
	 return prompt.enum_select("Pair?", choices, per_page: 8)
end
