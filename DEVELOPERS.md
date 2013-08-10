# Justbot Development

1. Fork on Github
2. `git checkout -b my-feature`
3. Hack away
4. Merge changes from `justjake/justbot:master`
5. Submit a github pull request

## Generated Documentation

*Online documentation for Justbot*:
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

## Adding Featuers

### Creating a Plugin

Creating a Justbot plugin is almost identical to the system for creating
Cinch plugins. There are just a couple of extra steps:

1. All plugins go in {Justbot::Plugins}, as files inside of
   `lib/plugins`. 

2. Plugins include both Cinch::Plugin (this gives you all the
   handy-dandy Cinch plugin definition methods) AND {Justbot::Helpful},
   which adds support for the Justbot help system.

3. You should add your plugin to the list of all plugins,
   {Justbot::Plugins::All} at the end of your class definition.
   This allows bots to include all plugins at once without having to
   modify the bot's executable file.


Here's the bare minimum plugin definition:

```ruby

    module Justbot
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

```

Use {Justbot::Models::Tag} to add permissions and capability identifiers
to your plugin's registered users.

See {file:lib/justbot/plugins/tweet.rb the tweeting plugin} for a simple
example from the codebase.

### Models

If your plugin needs to persist additional information into the database,
please define your models in `lib/justbot/models/your_plugin.rb`, then
require that file from your plugin. You may add a relationship between
the models your plugin introduces and {Justbot::Models::User} by
re-opening the User class:

```ruby

    module Justbot
      module Models
        # define your new model as belonging to User
        class MyGreatModel
          belongs_to :user, key: true
        end

        # re-open user to add ownership of MyGreatModel
        class User
          has 1, :greatmodel, 'MyGreatModel'
        end
      end
    end

```

See {file:lib/justbot/models/twitter.rb the Twitter model} for an
example of this in practice.
