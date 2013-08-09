# JustBot Development

1. Fork on Github
2. `git checkout -b my-feature`
3. Hack away
4. Merge changes from `justjake/justbot:master`
5. Submit a github pull request

## Generated Documentation

*Online documentation for JustBot*:
http://rubydoc.info/github/justjake/justbot/frames

*Documentation for [Cinch][c]*:

* Getting Started: [here][cgs]
* Main docs: http://rubydoc.info/gems/cinch/frames
* Directives availiable to create plugins:
  http://rubydoc.info/gems/cinch/Cinch/Plugin/ClassMethods

*Documentation for DataMapper*, our ORM: http://datamapper.org/docs/

[c]: https://github.com/cinchrb/cinch/
[cgs]: http://rubydoc.info/github/cinchrb/cinch/file/docs/getting_started.md

## Architecture

Justbot has three major components:

1. It is a collection of Chinch plugins. These you could consider
   ViewControllers if you want to look at this as an MVC-style project.
   A plugin defines a set of responses to IRC events.

2. It provides a friendly help system for plugin authors, allowing you
   to easily document your Cinch matches so your users can query the IRC
   bot for usage information. See {Justbot::Helpful} for useful IRC help
   tools.

3. It manages user authentication and authorization for plugins, with a
   DataMapper ORM backend, so it can run atop any of the databases
   DataMapper supports.

### Justbot execution steps

See `bin/justbot` for the primary example of a bot using this project.

1. Use `Bundler` so we have only the gems defined in our gemfile.
2. Load definitions of all models so we can `DataMapper.finalize!` which
   confirms model valididy and instantiates the ORM runtime.
3. Load Cinch and Justbot plugins
4. Define a new Chinch bot and hook up our plugins
5. Connect the bot to the IRC server

Read the [Cinch getting started documentation][cgs] to get a feel for how
Justbot's IRC system works.

### Architecture TODOs

These are in order of importance.

1. Create {Justbot::Models} to store our DataMapper models, in a
   directory like `models`. Relocate {Justbot::User}.

1. Define or import a flexible authorization model. Right now we just
   confirm if a user is an administrator ({Justbot::User#is_admin?}). We
   need permission authrizations that plugins can define.

   This should be called {Justbot::Authorization}.

1. Reorganize the directory structure to group all code under
   `lib/justbot` instead of everything just lying around un-prefixed in
   `lib` so we can think about becoming a Rubygem someday or something.

## Creating a plugin

Creating a JustBot plugin is almost identical to the system for creating
Cinch plugins. There are just a couple of extra steps:

1. All plugins go in {JustBot::Plugins}, as files inside of
   `lib/plugins`. 

2. Plugins include both Cinch::Plugin (this gives you all the
   handy-dandy Cinch plugin definition methods) AND {Justbot::Helpful},
   which adds support for the JustBot help system.

3. You should add your plugin to the list of all plugins,
   {Justbot::Plugins::All} at the end of your class definition.
   This allows bots to include all plugins at once without having to
   modify the bot's executable file.

Here's the bare minimum plugin definition:

    module JustBot
        module Plugins
            # Cool new plugin
            class MyNewPlugin
                include Cinch::Plugin
                include Justbot::Helpful
                
                # ... cinch plugin definition ...
            end

            # add my plugin to the list of all plugins
            All << MyNewPlugin
        end
    end


