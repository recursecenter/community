class Ability
  include CanCan::Ability

  def initialize(user)
    can :me, User

    can :read, SubforumGroup

    can :read, Subforum

    alias_action :subscribe, :unsubscribe, to: :read
    can [:create, :read], DiscussionThread

    can [:create, :update], Subscription, user: user

    can [:create, :read], Post
    can :update, Post, author: user

    alias_action :read, to: :update
    can :update, Notification, user: user
  end
end
