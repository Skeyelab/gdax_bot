def gdax_bot_main_menu
	 redis = Redis.new

	 loop do
 		 prompt = TTY::Prompt.new
 		 choice = prompt.select('Choose your destiny?') do |menu|
  			 menu.enum '.'

  			 # menu.choice 'Open and Close Order', 'open_and_close'
  			 menu.choice 'Trailing Stop', 'trailing_stop'
  			 menu.choice 'View Data Stream', 'view_websocket'
  			 menu.choice 'Prompt', 'prompt'
  			 menu.choice 'Exit', 'exit'
  		end

 		 case choice
  		when 'exit'
  			 abort
  		when 'prompt'
  			 binding.pry
  		when 'view_websocket'
  			 view_websocket
  		when 'trailing_stop'
  			 trailing_start_menu
  		end
 	end
end
