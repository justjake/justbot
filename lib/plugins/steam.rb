require "steam-condenser"
# a Steam Community group.
# defined here for a monkey-patch
# @see http://koraktor.de/steam-condenser/
class SteamGroup
  # patch SteamGroup so we can get the parsed "xml" data
  attr_reader :xml_data
end

module Justbot
  module Plugins
    # plugin to inspect Steam Community state
    class SteamPowered
      include Cinch::Plugin
      include Justbot::Helpful

      self.plugin_name = "Steam"
      self.help = "Query steam for information about groups or people"

      document 'steam online', 'shows online user count info for the RCB group'
      match /steam online/, method: :show_online

      attr_accessor :group

      def initialize *args
        super
        # the UCB Rescomp Steam Group
        @group = SteamGroup.new(103582791430123500)
      end

      # print the users online in @group to IRC
      def show_online(m)
        # update group
        synchronize(:steam) do
          @group.fetch
        end
        details = @group.xml_data['groupDetails']
        m.reply('Users online for ' + details['groupName'])
        m.reply("%s online, %s in game" % [details['membersOnline'], details['membersInGame']])
      end
    end
    All << SteamPowered
  end
end