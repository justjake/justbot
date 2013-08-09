# "JustBot" IRC Bot

by Jake Teton-Landis <just.1.jake@gmail.com>
copyright 2012, all rights reserved

## About

You can discover the plugins availible in Justbot by looking at {Justbot::Plugins}

Here are a few of the better features:

*   tweet right from irc by typing `!tweet <update text>`
*   follow all your Rescomp freinds at once by typing `JustBot: twitter followall`
*   bask in the warm glow of the social as JustBot prints tweets to ## in 3-color glory!

This bot is build on the Cinch framework, a ruby library for building
IRC bots which features a nicely threaded design. It allows you to build
bot capabilities through plugins, so you can easily separate bot functionality.

There are a few components that are not Cinch-dependent, such as the DataMapper users
support, but they are ment to be used from Cinch plugins.


## Requirements

### Core Requirements

In order of importance:

1.  Ruby 1.9.1 or better. Tested to work with 2.0.0-p247 as well.
2.  [Cinch][1] framework (`gem install cinch`) is the core library for the bot.
3.   Two (!) gems are used for interfacing with the Twitter APIs:
    1.  **`twitter`** is used for most Twitter API interaction
    2.  **`twitter_oauth`** is used during user creation to get oauth tokens and twitter_id
4.   Users support depends on [DataMapper][2] for ORM, although only only 'dm-core', 'dm-migrations' and
    'dm-transactions' are required at present. It'll try to connect to a sqlite database in
    `config` by default. Edit `lib/database.rb` to customize.
5.   Tweets are run through [HTMLentities][3] before being displayed, so you'll
    need to have that gem installed, too

[1]: https://github.com/cinchrb/cinch/
[2]: http://datamapper.org/
[3]: http://htmlentities.rubyforge.org/

### More Requirements

*   **{Justbot::Session}**, **{Justbot::User}**: these modules have inline Rspec tests. Install '`rspec`' or
    remove the tests.
*   **{Justbot::Plugins::SteamPowered}**: requires '`steam-condenser`', an apllingly poor gem for interacting
    with Valve Software's products.
*   **This documentation** is generated using [YARD](http://yardoc.org/) but really if you like Ruby
    (or even use it at all) you should have `yard server --gems` running somewhere.


## Bot Usage from IRC

`/msg <botname> help` will give you an overview of the active plugins in a bot
instance:

     > help
    Help for JustBot
    plugins:
    Administration, Friendly, Help, Registration, Sessions, Tweet, TwitterFeed, Steam
    help in Help
      help [PLUGIN] [COMMAND]
      show help information for the bot, for PLUGIN in bot, or for a COMMAND in PLUGIN

You can then query to get help about specific plugins. Plugin help uses prefix-based matching,
so '`help admin`' will show the help for the `Adimistration` plugin.

The confusing thing is, commands are not called prefixed by module name. For example, if you wanted
to get help about command `twitter follow` in module `TwitterFeed` you might type the following:

    > JustBot: help twit twitter follow
    or
    > /msg JustBot help twit twitter follow

but to actually request the command, you would type

    > JustBot: twitter follow @justbotirc
    or
    > /msg JustBot twitter follow @justbotirc

## Developments

### Source Code Access

Justbot is now open-source! I still need to move the Twitter modules to
read config from environemnt variables, but for now the config file for
twitter stuff, `config/twitter.yaml` just has my personal Oauth keys
missing.

Visit JustBot online at https://github.com/justjake/justbot

### TODOs

1. Refactor user registration so that it does not depend on Twitter
   oauth. A user should be able to register without twitter

2. Refactor the `User` model so that Twitter accounts are seperate
   from JustBot users. Add `TwitterAccount` model with 1:1 link to
   `User`.

3. Set up documentation auto-publishing.

### Project Idea: SaltyBot

Provide an IRC interface to SaltyBet. The bot will manage a shared
SaltyBet user account with Illuminati privelages. It should post the
names and rankings of contenders each time a new match occurs.

Users in the channel vote on which contender SaltyBot should place its
bet on.

Mockup:

    SaltyBot> Round 9245                                     $4570 SaltyBucks 
    SaltyBot> ================================VS=============================
    SaltyBot> Vegeta SSJ4                                          Jonny Cage
    SaltyBot> 12/0/2 - 85.71% win, 70% conf         6/2/0 - 75% win, 50% conf
    ...
    jitl>  SaltyBot: bet vegeta
    gchao> SaltyBot: bet jonny
    ...
    SaltyBot> Voting results: 1 for "Vegeta SSJ4", 1 for "Jonny Cage"
    SaltyBot> Betting $100 on "Vegeta SSJ4" (better win ratio in tie)
    ...
    SaltyBot> TO THE SALT MINES WITH YOU: sanic4lyfe ($50), bobparr
              ($9001), margretThatcher ($299), IvanTheTerrible ($400)
    ...
    SaltyBot> Round 9245 over: Jonny Cage wins!
    SaltyBot> jitl: Apply yourself. This is your fourth bad call today.
    SaltyBot> gchao: Don't get cocky, kid.

When ties occur in voting, SaltyBot will bet less money, and bet on the
better of the two contendors.

## To Run

    $ cd /path/to/bot/
    $ ruby bin/justbot
