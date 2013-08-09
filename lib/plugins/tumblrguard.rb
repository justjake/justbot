module Justbot
  module Plugins
    # warns and then kicks people who mention tumblr too many times
    class TumblrGuard
      include Cinch::Plugin
      include Justbot::Helpful

      self.plugin_name = 'TumblrGuard'
      self.help = 'kicks you if you mention tumblr'

      # stores warned users
      class WarnedStruct < Struct.new(:channel, :time, :said)
        def to_s
          "mentioned Tumblr at #{time.asctime} in ##{channel}"
        end
      end

      # stores kicked users
      class KickedStruct < Struct.new(:user, :channel, :time, :said)
        def to_s
          "#{user} was kicked from #{channel} at #{time} for saying `#{said}`"
        end
      end

      # @!group Regex Matches
      # @!macro [attach] match
      #   @!method <Bot Name>$1(command, params)
      #   @note This is a command used from IRC.
      #     its parameters are captured directly via Regex
      #     and then passed to the corrosponding Ruby method
      #   @return [nil]
      #   @see #${-1}
      match /[tT]umbl[ue]?r/, use_prefix: false,  method: :tumblr_mentioned
      match /mentioned (.+)/,                     method: :has_mentioned
      match /kick(?: (on|off|status))?/,               method: :kick_mode
      match /kicked/,                             method: :show_kicked
      # @!endgroup

      def initialize(*args)
        super
        @warnings = {}
        @kicked = []
        @should_kick = true
      end

      # Watches for any mention of tumblr via a regex
      # gives users a warning the first time
      # kicks them the second time
      # ignores admin users
      # @example
      #   TumblrLover> man such a cool post I made on tumblr
      #   JustBot> TumblrLover: tumblr is scum. do not mention it again
      #   TumblrLover> I love tumblr, and there's nothing you can do about it
      #   TumblrLover was kicked from #okcupid by JustBot [explanation]
      def tumblr_mentioned(m)
        s = Session(m)
        if (m.user.nick == @bot.nick) || (s && s.user.is_admin?)
          debug "Tumbler mentioned by #{m.user.nick}, but not acted on"
        else
          if (@warnings.include? m.user.nick) && @should_kick
            debug "trying to kick #{m.user.nick}"
            m.channel.kick(m.user, @warnings[m.user.nick].to_s)
            @kicked << KickedStruct.new(m.user.nick, m.channel.name, Time.now, m.message)
          else
            m.reply("tumblr is scum. do not mention it again.", true)
            @warnings[m.user.nick] = WarnedStruct.new(m.channel.name, Time.now)
          end
        end
        debug @warnings.to_s
      end

      # has a given user mentioned tumblr yet?
      # @example
      #   JustBot: mentioned [nickname]
      def has_mentioned(m, nick)
        if @warnings.include? nick
          m.reply("#{nick} " + @warnings[nick].to_s, true)
          true
        else
          m.reply("Nick #{nick} has no warnings", true)
          false
        end
      end

      # Set or query whether we're kicking people
      # @example
      #   JustBot: kick (on|off|status)
      def kick_mode(m, setting = 'status')
        s = Session(m)
        if s && s.user.is_admin?
          case setting
            when "on"
              @should_kick = true
            when "off"
              @should_kick = false
          end
          if @should_kick
            m.reply("tumblr kicking is on", true)
          else
            m.reply("tumblr kicking is off", true)
          end
        else
          m.reply('not authorized to make changes', true)
        end
      end

      # Show the number of users kicked by this plugin since last launch
      # @example
      #   JustBot: kicked
      def show_kicked(m)
        m.reply("I've kicked #{@kicked.length} users.")
        m.reply("Last kick: " + @kicked.last.to_s) if @kicked.length
      end
    end
  end
end
