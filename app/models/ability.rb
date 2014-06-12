class Ability
  include CanCan::Ability

  def initialize(user)
    can :me, User

    can :read, SubforumGroup

    can :read, Subforum

    can [:create, :read], DiscussionThread

    can :create, Post
    can :update, Post, author: user

    alias_action :read, to: :update
    can :update, Notification, user: user
  end
end
