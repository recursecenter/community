class VisitedStatus < ActiveRecord::Base
  belongs_to :user
  belongs_to :visitable, polymorphic: true

  validate :unique_for_visitable_and_user, on: :create

  def unique_for_visitable_and_user
    unless self.class.where(user_id: user_id,
                            visitable_id: visitable_id,
                            visitable_type: visitable_type).empty?

      errors[:base] << "There can be only one VisitedStatus for a given user and visitable."
    end
  end
end
