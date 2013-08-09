module Justbot
  module Plugins
    # Bot plugin to act like a nice citizen.
    # responds to "welcome"-like greetings,
    # and to compliments
    # and also asks people if they are, indeed, mad
     class Friendly
       include Cinch::Plugin
       include Justbot::Helpful

       self.plugin_name = 'Friendly'
       self.help = "s/tries to be nice/trolls harder/g"

       match /(?:hello|hi|howdy|welcome)/i,       method: :greet
       match /(?:good job|awesome|well played|wow)/i, method: :say_thanks
       match /[tT]hanks?(?: you)?/i,                     method: :youre_welcome
       match /[Ff]+[Uu]{2,}/, use_prefix: false,    method: :query_mad

       def initialize *args
         super

         @mad_users = {}
         @leet_targets = ['##', '#general']


         # 13:37 (!)
         on_1337 = lambda do
           run_at(next_1337, &on_1337)
           @leet_targets.each{|t| Target(t).send("13:37 (!)")}
         end

         run_at(next_1337, &on_1337)
       end

       # reply to nice greetings
       # @example
       #   JustBot: welcome!
       def greet(m)
         m.reply("Hi", true)
       end

       # say thank you
       # @example
       #   JustBot: well played
       def say_thanks(m)
         m.reply("Thanks!", true)
       end

       # say you're welcome
       def youre_welcome(m)
         m.reply("np bro", true)
       end


       # you mad bro?
       def query_mad(m)
         user_is_mad = false
         user_is_mad = synchronize(:mad) { @mad_users.include? m.user.nick}
         if user_is_mad
           m.reply("wow #{m.user.nick} mad")
         else
           m.reply("you mad bro?", true)
           synchronize(:mad) do
             remove_mad = Timer(60, shots: 1) {@mad_users.delete(m.user.nick)}
             @mad_users[m.user.nick] = remove_mad
             remove_mad.start
           end
         end
       end

       # get the next time it will be 13:37
       # @return [Time] datetime at 13:37
       def next_1337
         now = Time.now
         leet_today = Time.local(now.year, now.month, now.day, 13, 37)
         # hasn't happended today
         return leet_today if leet_today > Time.now
         # tomorrow
         leet_today + (60 * 60 * 24)
       end

       # run a proc at the given time using the built-in timer feature and basic math
       # @param [Time] time when to run the block
       # @yield the block to run
       # @return [Cinch::Timer] a run-once event timer
       def run_at(time, &block)
         seconds_until = time - Time.now
         t = Timer(seconds_until, shots: 1 , &block)
         t.start
         return t
       end
     end


    # add to Plugins::All
    All << Friendly
  end
end