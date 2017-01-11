class DestroyDeactivatedUserSubscriptions < ActiveRecord::Migration
  def up
    Subscription.joins(:user).where(users: {deactivated: true}).delete_all
  end
end
