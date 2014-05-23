class Ability
  include CanCan::Ability

  def initialize(user)
    can :me, User

    can :read, SubforumGroup

    can :read, Subforum

    can [:create, :read], DiscussionThread
    can :create, DiscussionThread

    can [:create, :update], Post, author: user
  end
end
