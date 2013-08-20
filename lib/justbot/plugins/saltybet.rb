require 'salty'
module Justbot
  module Plugins
    # Interact with SaltyBet.com via IRC!
     class SaltyBets
       include Cinch::Plugin
       include Justbot::Helpful

       self.plugin_name = 'SaltyBets'
       self.help = "s/tries to be nice/trolls harder/g"

       document 'salty status', 'show the current status of betting from SaltyBet.com'
       match /salty status/i,       method: :status
       
       document 'set uiwidth=', 'set uiwidth=COLS',
         'set the response width from SaltyBet for replies to you.'
       match /set uiwidth=([0-9]+)/, method: :set_width_for_nick

       UI_WIDTH = 60
       VERSUS = 'VS'

       def initialize(*args)
         super(*args)

         @client = Salty::Client.new(nil, nil)
         @user_prefs = {}
       end

       def set_width_for_nick(m, width)
         @user_prefs[m.user.nick] = width.to_i
         m.reply("set uiwidth = #{width.to_i}")
       end

       def fill_space(allwords, intended_width, subdivide = 1)
         space_left = (intended_width - allwords.length) / subdivide
         space_left = 1 if space_left < 0
         return " " * space_left
       end

       def status(m)
         state = @client.get_state!
         width = @user_prefs[m.user.nick] || UI_WIDTH

         if state.betting?
           bet_status = "[BETS OPEN]"
           p1 = state.p1.name
           p2 = state.p2.name
         else
           bet_status = "[BETS LOCKED]"
           p1 = "#{state.p1.name} ($#{state.p1.total})"
           p2 = "#{state.p2.name} ($#{state.p2.total})"
         end

         title = "Salty's Dream Cast Casino"
         user_count = state.bettors.length.to_s + " bettors"

         spacer_1 = fill_space(title + user_count + bet_status, width, 2)
         spacer_2 = fill_space(p1 + p2 + VERSUS, width, 2)

         m.reply(Format(:green, title) + spacer_1 + user_count + spacer_1 + bet_status)
         m.reply(Format(:red, p1) + spacer_2 + VERSUS + spacer_2 + Format(:bold, Format(:blue, p2)))
       end

     end # end Salty

     All << SaltyBets

  end # end plugins
end
