class Ability
  include CanCan::Ability

  def initialize(user)
    @user = user

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

  def can?(action, resource)
    if resource.respond_to?(:required_roles)
      @user.satisfies_roles?(*resource.required_roles) && super
    else
      super
    end
  end
end
