require 'set'
module Justbot
  # Database-persistent data in Justbot.
  # Models are mapped into our SQlite database using DataMapper.
  module Models

    # A user. Contains a hashed password and permission authentications
    class User
      include DataMapper::Resource
      property :id,                     Serial
      property :name,                   String, required: true
      property :password,               String, required: true, length: 90
      # simple string tags. useful for permissions
      has n, :tags, 'PersistentTag'

      # test to see if the given password would authenticate the user
      # @param password [String]
      def authenticates?(password)
        self.password == Crypto::digest(password)
      end

      # Query if this user has a tag of the given type
      # @param tag [Tag]
      # @return [Boolean]
      def has_tag?(tag)
        self.tags.count(:name => tag.name)> 0
      end

      # Tag this User with a tag of a given type
      # @param tag [Tag]
      def add_tag(tag)
        self.tags.new(:name => tag.name)
      end

      # Tag this User with a tag of a given type and immediatly save this tag add
      # @param tag [Tag]
      def add_tag!(tag)
        tag = add_tag(tag)
        tag.save
      end

      # Remove any tags of the given type from this user
      # @param tag [Tag]
      def remove_tag(tag)
        self.tags.all(:name => tag.name).destroy
      end

      # Should this user be considered a superuser in any plugin?
      # @see Justbot::Models::Tag::AdminTag
      def is_admin?
        self.has_tag? Justbot::Models::Tag::AdminTag
      end
    end


    # Simple model to tag users with string attributes
    # Can be used to implement permissions in plugins, etc
    # @private
    class PersistentTag

      # how long a tag description string can be
      MaxLength = 100

      include DataMapper::Resource
      property   :name, String, length: MaxLength, required: true
      belongs_to :user, :key => true
    end


    # Simple model to tag users with string attributes
    # Can be used to implement permissions in plugins, etc
    # You can manage the tags attatched to a {Justbot::Models::User} with
    # {Justbot::Models::User#add_tag}, {Justbot::Models::User#remove_tag},
    # and {Justbot::Models::User#has_tag?}
    #
    # @see {Justbot::Helpful::ClassMethods#define_tag}
    #
    # @example Usage in a plugin
    #   # could also be Justbot::Models::Tag.new
    #   QuizJudge = define_tag "user is a quiz judge"
    #
    #   def make_quiz_judge(m, nick)
    #     s = Session(m)
    #     if s && s.user.has_tag? @@quiz_judge
    #       other_user = Justbot::Models::User.first(:name => nick)
    #       if not other_user
    #         m.reply("no user by name '#{nick}' found")
    #         return
    #       end
    #
    #       other_user.add_tag(@@quiz_judge)
    #       m.reply("User '#{nick} is now a quiz judge")
    #       return
    #     end
    #     # not a quiz judge, so no permission to execute command
    #     m.reply("No permission to make someone a judge")
    #   end
    class Tag

      # list of all query methods that can have a 'name' associated with them
      NAME_METHODS = Set.new([
        :first,
        :last,
        :get,
        :count,
        :new
      ])
      private_constant :NAME_METHODS

      # rememeber what tag types have been created, to prevent two plugin 
      # authors from accidentally using conflicting tag names
      @@already_created_types = Set.new

      attr_reader :name

      # Define a new tag type of the given name.
      # Tag names must be unique across the program so that plugin 
      # functionality doesn't conflict.
      #
      # @see {Justbot::Models::Tag}
      #
      # @param tag_name [String] description of the tag's use
      # @return [Justbot::Models::Tag]
      def initialize(tag_name)
        # cannot create tags that will break the DB
        if tag_name.length > PersistentTag::MaxLength
          raise NameError.new("Tag name `#{tag_name}' over max length of #{PersistentTag::MaxLength}.")
        end

        # cannot re-create tag types
        if @@already_created_types.include? tag_name
          raise NameError.new("Tag name `#{tag_name}' already defined.")
        end

        @name = tag_name.freeze
        @@already_created_types.add(@name)
      end


      # Pass calls through to {Justbot::Models::PersistentTag} with the name
      # parameter always bound to @name
      def method_missing(m, *args, &block)
        if :m == :new and args.length == 0
          # create new tags with the fixed tag type
          args[0] = Hash.new
        end
        if NAME_METHODS.include? m 
          # always a hash. converts nil to a hash too
          args[0] = args[0].to_h
          # set :name in the kwargs to @tag_name
          # so the user precieves a Tag DataMapper class that always
          # selects with this tag's type
          args[0][:name] = @name
        end

        PersistentTag.public_send(m, *args, &block)
      end

      # Tag user as an administrator, who should be able to do anything
      # in any plugin
      AdminTag = Tag.new("user is an administrator")

    end
  end
end
