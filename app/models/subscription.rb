class Subscription < ActiveRecord::Base
  belongs_to :subscribable, polymorphic: true
  belongs_to :user

  validate :unique_for_subscribable_and_user, on: :create

  def subscribe
    self.subscribed = true
    self.reason = "You are receiving emails because you subscribed to this #{resource_name}."
    save!
  end

  def unsubscribe
    self.subscribed = false
    self.reason = "You are not receiving emails because you have unsubscribed."
    save!
  end

  def resource_name
    if subscribable.respond_to?(:resource_name)
      subscribable.resource_name
    else
      subscribable.class.name.downcase
    end
  end

private
  def unique_for_subscribable_and_user
    unless self.class.where(user_id: user_id,
                            subscribable_id: subscribable_id,
                            subscribable_type: subscribable_type).empty?

      errors[:base] << "There can be only one Subscription for a given user and subscribable."
    end
  end
end
